# Chz-Login — pacote revisado

Este pacote reúne a tela de login, a validação oficial via APIClient, o armazenamento no Keychain e os assets CHZ PRIV fornecidos.

## Alterações

- Removida a validação automática de key salva na abertura, evitando dismiss antes da interação.
- O login inicia somente após o usuário tocar em ENTRAR.
- Key vazia, falha de rede ou rejeição do servidor mantêm a tela aberta.
- O dismiss ocorre somente no callback oficial de sucesso do cliente de autenticação.
- Adicionados indicador de carregamento, mensagens de estado e bloqueio de duplo envio.
- Integrados `Resources/CHZPrivLogo.png` e `Resources/discord.png`.
- Ajustadas proporções, glow, cartão, espaçamentos e layout responsivo.
- Adicionado `.gitignore` para impedir o versionamento de secrets, certificados e artefatos.

## Configuração obrigatória

Configure o secret privado `CHZ_API_TOKEN` no ambiente de build. Inclua os dois arquivos de `Resources/` no target e em Copy Bundle Resources. Não inclua tokens, AES keys, Public API keys, certificados ou chaves privadas no repositório.

## Limitação

A revisão foi estática. A compilação, assinatura e teste final exigem macOS/Xcode e um dispositivo autorizado. O pacote não contém uma garantia de compilação ou funcionamento sem testes nesse ambiente.
