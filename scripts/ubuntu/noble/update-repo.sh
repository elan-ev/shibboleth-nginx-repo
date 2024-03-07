#!/usr/bin/env sh

_PWD="$PWD"
set -e
apt update
apt install -y dpkg-dev
mkdir -p /repo/dists/noble/multiverse/binary-amd64
cd /repo/
dpkg-scanpackages --arch amd64 --multiversion pool/ > dists/noble/multiverse/binary-amd64/Packages
gzip -9 > dists/noble/multiverse/binary-amd64/Packages.gz < dists/noble/multiverse/binary-amd64/Packages

hash_files() {
    FILES_TO_HASH="$*"
    echo MD5Sum:
    for FILE_TO_HASH in $FILES_TO_HASH; do
        case $FILE_TO_HASH in
        Release*);;
        *) echo " $(md5sum $FILE_TO_HASH | cut -d' ' -f1) $(wc -c $FILE_TO_HASH)";;
        esac
    done
    echo SHA1:
    for FILE_TO_HASH in $FILES_TO_HASH; do
        case $FILE_TO_HASH in
        Release*);;
        *) echo " $(sha1sum $FILE_TO_HASH | cut -d' ' -f1) $(wc -c $FILE_TO_HASH)";;
        esac
    done
    echo SHA256:
    for FILE_TO_HASH in $FILES_TO_HASH; do
        case $FILE_TO_HASH in
        Release*);;
        *) echo " $(sha256sum $FILE_TO_HASH | cut -d' ' -f1) $(wc -c $FILE_TO_HASH)";;
        esac
    done
}

cd dists/noble
cat <<EOF > Release
Origin: Shibboleth Nginx Module Repository
Suite: noble
Codename: noble
Version: 24.04
Architectures: amd64
Components: multiverse
Description: This repository provides a build of Shibboleth auth request module for Nginx.
Date: $(date -Ru)
$(hash_files multiverse/binary-amd64/Packages*)
EOF
# Sign repo
apt install -y gpg
GPG_KEY_ID=$(echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --show-keys --with-colons | grep -m1 "sec:u" | cut -d: -f5)
echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
cat Release | gpg -u "$GPG_KEY_ID" -abs > Release.gpg
cat Release | gpg -u "$GPG_KEY_ID" -abs --clearsign > InRelease
cd "$_PWD"