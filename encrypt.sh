#!/bin/bash

# Enable fail detection in pipelines
set -o pipefail

# Function to validate passphrase strength
validate_passphrase() {
    local pass="$1"

    # Minimum length 12 characters
    if [ "${#pass}" -lt 12 ]; then
        echo "Passphrase must be at least 12 characters long."
        return 1
    fi

    # Must include at least one lowercase letter
    if ! [[ "$pass" =~ [a-z] ]]; then
        echo "Passphrase must contain at least one lowercase letter."
        return 1
    fi

    # Must include at least one uppercase letter
    if ! [[ "$pass" =~ [A-Z] ]]; then
        echo "Passphrase must contain at least one uppercase letter."
        return 1
    fi

    # Must include at least one number
    if ! [[ "$pass" =~ [0-9] ]]; then
        echo "Passphrase must contain at least one number."
        return 1
    fi

    # Must include at least one special character
    # if ! [[ "$pass" =~ [\!\@\#\$\%\^\&\*\(\)\_\+\-\=\[\]\{\}\;\:\,\.\<\>\/\?] ]]; then
    #     echo "Passphrase must contain at least one special character."
    #     return 1
    # fi

    return 0
}

# Prompt for passphrase with dual confirmation and validation
while true; do
    read -s -p "Enter strong passphrase: " PASSPHRASE
    echo
    read -s -p "Confirm passphrase: " PASSPHRASE_CONFIRM
    echo

    if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
        echo "Passphrases do not match. Please try again."
        continue
    fi

    if validate_passphrase "$PASSPHRASE"; then
        break
    else
        echo "Please choose a stronger passphrase."
    fi
done

dir="."

for d in "$dir"/*/; do
    dir_name=$(basename "$d")
    echo -e "NAVIGATED: \n\t>>> $dir_name"

    # Create deterministic archive (sorted)
    find "$d" -type f | LC_ALL=C sort | \
    tar --numeric-owner -T - -cf - \
    | zstd -6 -T0 \
    | gpg --symmetric --cipher-algo AES256 --compress-algo none \
        --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" \
        --no-symkey-cache --no-emit-version --force-mdc --no-armor \
        --personal-digest-preferences SHA512 \
        --output "$dir_name.tar.zst.gpg"

    if [ $? -eq 0 ]; then
        echo -e "\t>>> ENCRYPTED > $dir_name.tar.zst.gpg\n"
    else
        echo -e "\t!! FAILED TO ENCRYPT $dir_name !!\n" >&2
    fi
done

# #!/bin/bash

# dir="."

# # ls all directories as array in folder $dir
# directories=("$dir"/*/)
# for d in "${directories[@]}"; do
#     dir_name=$(basename "$d")
#     echo "Entering directory: $dir_name"
#     files=("$d"/*)
#     echo "Files in $dir_name:"
#     for file in "${files[@]}"; do
#         echo " - $(basename "$file")"
#     done

#     # create archive tar for each directory with compression of xz with high encryption
#     tar --numeric-owner \
#         -cf - "$d" \
#     | xz -9e --threads=0 \
#     | gpg --symmetric --cipher-algo AES256 --compress-algo none \
#           --batch --yes --passphrase "PackerMan" \
#           --no-symkey-cache --no-emit-version --no-armor \
#           --force-mdc --personal-digest-preferences SHA512 \
#           --output "$dir_name.tar.xz.gpg"
          
#     echo "Created $dir_name.tar.xz.gpg"
    
#     echo -e "\n\n"
# done


# # tar --numeric-owner \
# #     -cf - $dir \
# # | xz -9e --threads=0 \
# # | gpg --symmetric --cipher-algo AES256 --compress-algo none \
# #       --batch --yes --passphrase "PackerMan" \
# #       --no-symkey-cache --no-emit-version --no-armor \
# #       --force-mdc --personal-digest-preferences SHA512 \
# #       --output archive.tar.xz.gpg

# # echo "Created archive.tar.xz.gpg"

# # tar --owner=0 --group=0 --numeric-owner \
# #     --mtime='UTC 2000-01-01' \
# #     --pax-option='delete=atime,delete=ctime' \
# #     -cf - x \
# # | xz -9e --threads=0 \
# # | gpg --symmetric --cipher-algo AES256 --compress-algo none \
# #       --no-symkey-cache --no-emit-version --force-mdc \
# #       --personal-digest-preferences SHA512 \
# #       --armor \
# #       --output archive.tar.xz.asc