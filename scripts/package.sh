#!/bin/bash
# Package and notarize a command line tool
# package.sh PRODUCT_NAME BUNDLE_ID EXECUTABLE_NAME VERSION

productname=$1
identifier=$2
executable=$3
version=$4

# the email address of your developer account
dev_account="me@brettterpstra.com"

# the name of your Developer ID installer certificate (for PKG signing)
# Leave empty or set to "-" to build unsigned PKG
INSTALLER_SIGNATURE="${INSTALLER_SIGNATURE:-Developer ID Installer: Brett Terpstra (47TRS7H4BH)}"

# the 10-digit team id
dev_team="47TRS7H4BH"

# the label of the keychain item which contains an app-specific password
dev_keychain_label="Developer-notarytool"

projectdir='.'

builddir="$projectdir"
pkgroot="$builddir/package"

requeststatus() { # $1: requestUUID
	requestUUID=${1?:"need a request UUID"}
	req_status=$(xcrun notarytool info \
		--keychain-profile "$dev_keychain_label" \
		"$requestUUID" 2>&1 |
		awk -F ': ' '/status:/ { print $2; }')
	echo "$req_status"
}

notarizefile() { # $1: path to file to notarize, $2: identifier
	filepath=${1:?"need a filepath"}
	identifier=${2:?"need an identifier"}

	# upload file
	echo "## uploading $filepath for notarization"
	requestUUID=$(xcrun notarytool submit --wait \
		--keychain-profile "$dev_keychain_label" \
		"$filepath" 2>&1 |
		awk '/  id:/ { print $NF; }' | tail -n 1)

	echo "Notarization RequestUUID: $requestUUID"

	if [[ $requestUUID == "" ]]; then
		echo "could not upload for notarization"
		exit 1
	fi

	# # wait for status to be not "in progress" any more
	# request_status="In Progress"

	# while [[ "$request_status" == "In Progress" ]]; do
	#     echo -n "waiting... "
	#     sleep 10
	#     request_status=$(requeststatus "$requestUUID")
	#     echo "$request_status"
	# done

	# print status information
	xcrun notarytool info \
		--keychain-profile "$dev_keychain_label" \
		"$requestUUID"
	echo

	# if [[ $request_status != "success" ]]; then
	#     echo "## could not notarize $filepath"
	#     exit 1
	# fi

}

# Build the binary
xcrun swift build -c release --arch arm64 --arch x86_64
bindir=$(xcrun swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

# Determine signing identity (allow override via environment variable)
APP_SIGNING_IDENTITY="${APP_SIGNING_IDENTITY:-Developer ID Installer: Brett Terpstra (47TRS7H4BH)}"

# Check if the identity exists, if not use ad-hoc signing
if security find-identity -v -p codesigning | grep -q "$APP_SIGNING_IDENTITY"; then
	echo "## Signing with: $APP_SIGNING_IDENTITY"
	codesign --force --verbose --sign "$APP_SIGNING_IDENTITY" -o runtime --timestamp $bindir/$executable
	codesign --verify -vvvv $bindir/$executable
	SKIP_NOTARIZATION=false
else
	echo "## Warning: Identity '$APP_SIGNING_IDENTITY' not found, using ad-hoc signing"
	codesign --force --verbose --sign "-" $bindir/$executable
	codesign --verify -vvvv $bindir/$executable
	SKIP_NOTARIZATION=true
fi

rm -rf package
mkdir -p package/usr/local/bin
cp $bindir/$executable package/usr/local/bin/

pkgpath="$builddir/$productname-$version.pkg"

echo "## building pkg: $pkgpath"

# Check if installer signing identity is provided and exists
if [ -n "$INSTALLER_SIGNATURE" ] && [ "$INSTALLER_SIGNATURE" != "-" ]; then
	if security find-identity -v -p codesigning | grep -q "$INSTALLER_SIGNATURE"; then
		echo "## Signing PKG with: $INSTALLER_SIGNATURE"
		pkgbuild --root "$pkgroot" \
			--version "$version" \
			--identifier "$identifier" \
			--sign "$INSTALLER_SIGNATURE" \
			"$pkgpath"
		# PKG is signed, can be notarized (if binary was also properly signed)
		# SKIP_NOTARIZATION remains false if binary was signed, true if ad-hoc
	else
		echo "## Warning: Installer identity '$INSTALLER_SIGNATURE' not found, building unsigned pkg"
		pkgbuild --root "$pkgroot" \
			--version "$version" \
			--identifier "$identifier" \
			"$pkgpath"
		SKIP_NOTARIZATION=true
	fi
else
	echo "## Building unsigned PKG (installer signing not configured)"
	pkgbuild --root "$pkgroot" \
		--version "$version" \
		--identifier "$identifier" \
		"$pkgpath"
	SKIP_NOTARIZATION=true
fi

# Only notarize if we have proper signing
if [ "$SKIP_NOTARIZATION" = "false" ]; then
	# upload for notarization
	echo "Path: $pkgpath"
	echo "Identifier $identifier"
	notarizefile "$pkgpath" "$identifier"

	# staple result
	echo "## Stapling $pkgpath"
	xcrun stapler staple "$pkgpath"
else
	echo "## Skipping notarization (ad-hoc or unsigned build)"
fi

exit $?
