{ ... }: {
  getConfig = {
    host,
    accessKeyId,
    secretAccessKey,
    encryptionKey ? null,
    gnupg ? null,
  }: let
    optionalEncryption = if encryptionKey != null then ''
      encrypt = True
      gpg_passphrase = ${encryptionKey}
      gpg_command = ${gnupg}/bin/gpg
      gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
      gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
    '' else "";
  in ''
    [default]
    host_base = ${host}
    access_key = ${accessKeyId}
    secret_key = ${secretAccessKey}
    host_bucket = %(bucket)s.${host}
    ${optionalEncryption}
  '';
}
