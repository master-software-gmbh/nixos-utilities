{ lib, ... }: {
  getSecret = name:
    if (lib.strings.hasInfix "-" name)
    then "{{ index .Data.data \"${name}\" }}"
    else "{{ .Data.data.${name} }}";
  getTemplate = secretPath: content: ''
    {{- with secret "${secretPath}" -}}
    ${content}
    {{- end -}}
  '';
}
