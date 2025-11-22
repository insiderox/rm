#!/bin/bash

# Enable fail detection in pipelines
set -o pipefail

read -s -p "Enter passphrase: " PASSPHRASE
echo

EXTRACT_DIR="./extracted"
mkdir -p "$EXTRACT_DIR"

encrypted_files=(*.tar.zst.gpg)
for encrypted_file in "${encrypted_files[@]}"; do
    base_name=$(basename "$encrypted_file" .tar.zst.gpg)
    echo -e "DECRYPTING: \n\t>> $encrypted_file"

    # Decrypt + decompress + extract with fail detection // zstd -d -q --threads=0 \
    if gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" --decrypt "$encrypted_file" \
        | tar --use-compress-program=unzstd --numeric-owner -xf - -C "$EXTRACT_DIR"; then
        echo -e "\t>> DECRYPTED > $EXTRACT_DIR/$base_name\n"
    else
        echo -e "\t!! DECRYPTION FAILED $encrypted_file !!\n" >&2
        # Optional: log error to a file
        # echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $encrypted_file failed decryption/extraction" >> decrypt_errors.log
    fi
done
