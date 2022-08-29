version=$1

# the email address of your developer account
dev_account="me@brettterpstra.com"

# the name of your Developer ID installer certificate
signature="Developer ID Installer: Brett Terpstra (47TRS7H4BH)"

# the 10-digit team id
dev_team="47TRS7H4BH"

# the label of the keychain item which contains an app-specific password
dev_keychain_label="Developer-altool"

# put your project's information into these variables

identifier="com.brettterpstra.gather-cli"
productname="gather-cli"

projectdir=$(dirname $0)

builddir="$projectdir"
pkgroot="$builddir/package"

requeststatus() { # $1: requestUUID
    requestUUID=${1?:"need a request UUID"}
    req_status=$(xcrun altool --notarization-info "$requestUUID" \
                              --username "$dev_account" \
                              --password "@keychain:$dev_keychain_label" 2>&1 \
                 | awk -F ': ' '/Status:/ { print $2; }' )
    echo "$req_status"
}

notarizefile() { # $1: path to file to notarize, $2: identifier
    filepath=${1:?"need a filepath"}
    identifier=${2:?"need an identifier"}
    
    # upload file
    echo "## uploading $filepath for notarization"
    requestUUID=$(xcrun altool --notarize-app \
                               --primary-bundle-id "$identifier" \
                               --username "$dev_account" \
                               --password "@keychain:$dev_keychain_label" \
                               --file "$filepath" 2>&1 \
                  | awk '/RequestUUID/ { print $NF; }')
                               
    echo "Notarization RequestUUID: $requestUUID"
    
    if [[ $requestUUID == "" ]]; then 
        echo "could not upload for notarization"
        exit 1
    fi
        
    # wait for status to be not "in progress" any more
    request_status="in progress"
    while [[ "$request_status" == "in progress" ]]; do
        echo -n "waiting... "
        sleep 10
        request_status=$(requeststatus "$requestUUID")
        echo "$request_status"
    done
    
    # print status information
    xcrun altool --notarization-info "$requestUUID" \
                 --username "$dev_account" \
                 --password "@keychain:$dev_keychain_label"
    echo 
    
    if [[ $request_status != "success" ]]; then
        echo "## could not notarize $filepath"
        exit 1
    fi
    
}

xcrun swift build -c release --arch arm64 --arch x86_64
bindir=$(xcrun swift build -c release --arch arm64 --arch x86_64 --show-bin-path)
rm -rf package
mkdir -p package/usr/local/bin
cp $binpath/gather package/usr/local/bin/

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

echo '## Done!'

exit 0
