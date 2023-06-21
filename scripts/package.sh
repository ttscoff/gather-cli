#!/bin/bash
# Package and notarize a command line tool
# package.sh PRODUCT_NAME BUNDLE_ID EXECUTABLE_NAME VERSION

productname=$1
identifier=$2
executable=$3
version=$4

# the email address of your developer account
dev_account="me@brettterpstra.com"

# the name of your Developer ID installer certificate
signature="Developer ID Installer: Brett Terpstra (47TRS7H4BH)"

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
                              "$requestUUID" 2>&1 \
                 | awk -F ': ' '/status:/ { print $2; }' )
    echo "$req_status"
}

notarizefile() { # $1: path to file to notarize, $2: identifier
    filepath=${1:?"need a filepath"}
    identifier=${2:?"need an identifier"}
    
    # upload file
    echo "## uploading $filepath for notarization"
    requestUUID=$(xcrun notarytool submit --wait \
                               --keychain-profile "$dev_keychain_label" \
                               "$filepath" 2>&1 \
                  | awk '/  id:/ { print $NF; }' | tail -n 1)
                               
    echo "Notarization RequestUUID: $requestUUID"
    
    if [[ $requestUUID == "" ]]; then 
        echo "could not upload for notarization"
        exit 1
    fi
        
    # # wait for status to be not "in progress" any more
    request_status="In Progress"

    while [[ "$request_status" == "In Progress" ]]; do
        echo -n "waiting... "
        sleep 10
        request_status=$(requeststatus "$requestUUID")
        echo "$request_status"
    done
    
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

xcrun swift build -c release --arch arm64 --arch x86_64
bindir=$(xcrun swift build -c release --arch arm64 --arch x86_64 --show-bin-path)
codesign --force --verbose --sign 'Developer ID Application: Brett Terpstra (47TRS7H4BH)' -o runtime --timestamp $bindir/$executable
codesign --verify -vvvv $bindir/$executable
rm -rf package
mkdir -p package/usr/local/bin
cp $bindir/$executable package/usr/local/bin/

pkgpath="$builddir/$productname-$version.pkg"

echo "## building pkg: $pkgpath"

pkgbuild --root "$pkgroot" \
         --version "$version" \
         --identifier "$identifier" \
         --sign "$signature" \
         "$pkgpath"

# upload for notarization
notarizefile "$pkgpath" "$identifier"

# staple result
echo "## Stapling $pkgpath"
xcrun stapler staple "$pkgpath"

exit $?
