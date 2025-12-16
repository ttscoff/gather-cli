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

	# upload file and wait for completion
	echo "## uploading $filepath for notarization"
	SUBMIT_OUTPUT=$(xcrun notarytool submit --wait \
		--keychain-profile "$dev_keychain_label" \
		"$filepath" 2>&1)

	echo "$SUBMIT_OUTPUT"

	# Extract the request UUID
	requestUUID=$(echo "$SUBMIT_OUTPUT" | awk '/  id:/ { print $NF; }' | tail -n 1)

	if [[ $requestUUID == "" ]]; then
		echo "## Error: could not get notarization request UUID"
		return 1
	fi

	echo "Notarization RequestUUID: $requestUUID"

	# Get detailed status
	echo "## Checking notarization status..."
	STATUS_OUTPUT=$(xcrun notarytool info \
		--keychain-profile "$dev_keychain_label" \
		"$requestUUID" 2>&1)

	echo "$STATUS_OUTPUT"

	# Extract status
	request_status=$(echo "$STATUS_OUTPUT" | awk -F ': ' '/status:/ { print $2; }' | head -1 | tr -d ' ')

	if [[ "$request_status" == "Accepted" ]]; then
		echo "## ✓ Notarization succeeded!"
		return 0
	else
		echo "## ✗ Notarization failed with status: $request_status"
		echo "## Getting notarization logs..."
		xcrun notarytool log \
			--keychain-profile "$dev_keychain_label" \
			"$requestUUID" 2>&1 | head -50
		return 1
	fi
}

# Build the binary
xcrun swift build -c release --arch arm64 --arch x86_64
bindir=$(xcrun swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

# Determine signing identity for binary (allow override via environment variable)
# Try Developer ID Application first (for notarization), fall back to 3rd Party Mac Developer Application
if [ -z "$APP_SIGNING_IDENTITY" ]; then
	# Try Developer ID Application first
	if security find-identity -v -p codesigning | grep -q "Developer ID Application: Brett Terpstra (47TRS7H4BH)"; then
		APP_SIGNING_IDENTITY="Developer ID Application: Brett Terpstra (47TRS7H4BH)"
	else
		# Fall back to 3rd Party Mac Developer Application
		APP_SIGNING_IDENTITY="3rd Party Mac Developer Application: Brett Terpstra (47TRS7H4BH)"
	fi
fi

# Initialize notarization flag - will be set based on PKG signing success
SKIP_NOTARIZATION=true

# Check if the identity exists, if not use ad-hoc signing
if security find-identity -v -p codesigning | grep -q "$APP_SIGNING_IDENTITY"; then
	echo "## Signing binary with: $APP_SIGNING_IDENTITY"
	if codesign --force --verbose --sign "$APP_SIGNING_IDENTITY" -o runtime --timestamp $bindir/$executable 2>&1; then
		codesign --verify -vvvv $bindir/$executable
		# Check if we're using Developer ID Application (required for notarization)
		if [[ "$APP_SIGNING_IDENTITY" == *"Developer ID Application"* ]]; then
			echo "## ✓ Binary signed with Developer ID Application (ready for notarization)"
		else
			echo "## Note: Using 3rd Party certificate - notarization will be skipped"
		fi
	else
		echo "## Warning: Failed to sign with '$APP_SIGNING_IDENTITY', trying ad-hoc signing"
		codesign --force --verbose --sign "-" $bindir/$executable
		codesign --verify -vvvv $bindir/$executable
	fi
else
	echo "## Warning: Identity '$APP_SIGNING_IDENTITY' not found, using ad-hoc signing for binary"
	codesign --force --verbose --sign "-" $bindir/$executable
	codesign --verify -vvvv $bindir/$executable
fi

rm -rf package
mkdir -p package/usr/local/bin
cp $bindir/$executable package/usr/local/bin/

pkgpath="$builddir/$productname-$version.pkg"

echo "## building pkg: $pkgpath"

# Check if installer signing identity is provided
if [ -n "$INSTALLER_SIGNATURE" ] && [ "$INSTALLER_SIGNATURE" != "-" ]; then
	# Try to use the certificate directly - pkgbuild can use installer certs
	# even if they don't show up in security find-identity
	echo "## Attempting to sign PKG with: $INSTALLER_SIGNATURE"
	if pkgbuild --root "$pkgroot" \
		--version "$version" \
		--identifier "$identifier" \
		--sign "$INSTALLER_SIGNATURE" \
		"$pkgpath" 2>&1; then
		echo "## ✓ PKG signed successfully"
		# PKG is signed with Developer ID Installer, can be notarized
		# BUT: Binary must also be signed with Developer ID Application for notarization to succeed
		if [[ "$APP_SIGNING_IDENTITY" == *"Developer ID Application"* ]]; then
			SKIP_NOTARIZATION=false
		else
			echo "## Note: Binary not signed with Developer ID Application - notarization will be skipped"
			SKIP_NOTARIZATION=true
		fi
	else
		PKG_BUILD_EXIT=$?
		echo "## Warning: Failed to sign with '$INSTALLER_SIGNATURE' (exit code: $PKG_BUILD_EXIT), building unsigned pkg"
		# Remove the failed signed package and build unsigned
		rm -f "$pkgpath"
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
	if notarizefile "$pkgpath" "$identifier"; then
		# Only staple if notarization succeeded
		echo "## Stapling $pkgpath"
		xcrun stapler staple "$pkgpath"
		if [ $? -eq 0 ]; then
			echo "## ✓ Package stapled successfully"
		else
			echo "## Warning: Stapling failed"
		fi
	else
		echo "## Error: Notarization failed, skipping stapling"
		echo "## The PKG is signed but not notarized. You may need to fix signing issues."
		exit 1
	fi
else
	echo "## Skipping notarization (ad-hoc or unsigned build)"
fi

exit $?
