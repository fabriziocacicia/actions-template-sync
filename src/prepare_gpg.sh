# Start GPG Agent
gpg-agent --daemon --allow-preset-passphrase --default-cache-ttl 60 --max-cache-ttl 60

# Import GPG Key
echo -n ${GPG_SIGNING_KEY} | base64 -d | gpg --pinentry-mode loopback --passphrase-file <(echo ${GPG_PASSHPHRASE}) --import
GPG_FINGERPRINT=$(gpg -K --with-fingerprint | sed -n 4p | sed -e 's/ *//g')
echo "${GPG_FINGERPRINT}:6:" | gpg --import-ownertrust

# Preset Passphrase In GPG Agent
GPG_KEYGRIP=`gpg --with-keygrip -K | sed -n '/[S]/{n;p}' | sed 's/Keygrip = //' | sed 's/ *//g'`
GPG_PASSPHRASE_HEX=`echo -n ${GPG_PASSHPHRASE} | od -A n -t x1 | tr -d ' ' | tr -d '\n'`
echo "PRESET_PASSPHRASE $GPG_KEYGRIP -1 $GPG_PASSPHRASE_HEX" | gpg-connect-agent

# Configure Git
export CI_SIGNINGKEY_ID=$( \
          gpg --list-signatures --with-colons \
          | grep 'sig' \
          | grep  ${GPG_COMMITTER_EMAIL} \
          | head -n 1 \
          | cut -d':' -f5 \
        )
git config --global user.name ${GPG_COMMITTER_NAME}
git config --global user.email ${GPG_COMMITTER_EMAIL}
git config --global user.signingkey $CI_SIGNINGKEY_ID
git config --global commit.gpgsign true
git config --global tag.gpgsign true
