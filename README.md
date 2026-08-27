# CHZ PRIV Login

Estrutura inicial para uma dylib de autenticação da CHZ PRIV usando a variante Lite Secure da API.

## Segurança

Não armazene tokens, certificados, perfis de provisionamento ou senhas no repositório. O token da API deve ser fornecido somente durante o build, por variável secreta do GitHub Actions ou por arquivo local ignorado pelo Git.

A key digitada pelo usuário deve ser persistida no Keychain do dispositivo somente após uma resposta de sucesso da API. Em caso de expiração ou invalidez, a key deve ser removida e a tela de login deve ser exibida novamente.

## Componentes planejados

- `Sources/CHZAuthManager.m`: configuração do cliente Lite Secure e validação da key.
- `Sources/CHZLoginViewController.m`: tela UIKit da CHZ PRIV.
- `Sources/CHZKeychain.m`: armazenamento seguro da key.
- `Config/CHZSecrets.example.h`: exemplo sem credenciais reais.
- `.github/workflows/build.yml`: workflow macOS a ser configurado depois da confirmação do método de assinatura.

## Configuração do token

Copie `Config/CHZSecrets.example.h` para `Config/CHZSecrets.h` apenas no ambiente privado de compilação e substitua o placeholder pelo token rotacionado. O arquivo real deve estar no `.gitignore`.

## Observação sobre a IPA

A IPA fornecida é compilada. A integração final exige uma dylib compatível, um método autorizado de carregamento, reassinatura com uma identidade válida e testes em um dispositivo autorizado. Este repositório começa apenas com a estrutura de código e não gera uma IPA instalável sozinho.
