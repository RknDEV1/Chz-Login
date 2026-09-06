# CHZ Login — Base funcional

Esta é a base estável do projeto `RknDEV1/Chz-Login` para futuras personalizações de telas de login.

## Referência funcional

A versão validada no dispositivo é a **build-101**. A release contém `CHZLogin.dylib` e `CHZLoginResources.bundle.zip`.

- Release: https://github.com/RknDEV1/Chz-Login/releases/tag/build-101
- Dylib: https://github.com/RknDEV1/Chz-Login/releases/download/build-101/CHZLogin.dylib
- Bundle: https://github.com/RknDEV1/Chz-Login/releases/download/build-101/CHZLoginResources.bundle.zip

## Comportamento aprovado

A key do AuthTool é validada na primeira entrada pelo package/token configurado. Depois da aprovação, a sessão é persistida no Keychain. Na reabertura do app, o bootstrap verifica a sessão local e libera o acesso sem enviar a mesma key novamente. A expiração é obtida do SDK, inclusive quando chega como `NSDate`, e a sessão é removida quando expira ou quando ocorre uma falha explícita.

A key não deve ser guardada em texto puro no `NSUserDefaults`. O Keychain é o armazenamento da credencial; `NSUserDefaults` pode conter apenas um marcador de existência da sessão.

## Arquivos principais

| Arquivo | Responsabilidade |
|---|---|
| `Sources/CHZAuthManager.m` | Configura o AuthTool, valida o callback, extrai a expiração e salva a sessão. |
| `Sources/CHZKeychain.m` | Persiste key, expiração e marcador local de sessão. |
| `Sources/CHZLoginBootstrap.m` | Decide se apresenta a tela ou libera o app pela sessão válida. |
| `Sources/CHZLoginViewController.m` | Interface, entrada da key, mensagens e botão de UDID. |
| `Resources/` | Logo, ícone e bundle visual da tela. |
| `.github/workflows/build.yml` | Compilação arm64, empacotamento e publicação da release. |

## Procedimento para novos clientes

Clonar o repositório, preservar o fluxo de `CHZAuthManager`, `CHZKeychain` e `CHZLoginBootstrap`, substituir apenas identidade visual, textos, URL de UDID e token/package autorizado, e gerar uma nova release pelo workflow. Depois, no ESign, substituir a dylib e o bundle, remover as entradas antigas do Assign, adicionar novamente os dois arquivos e assinar a IPA.

Não alterar a persistência, o controle de expiração ou o callback de sucesso sem testar o ciclo completo: primeira autenticação, encerramento pelo seletor de tarefas, reabertura e expiração da sessão.

## Observação sobre invalidação no painel

A sessão local reconhece a expiração armazenada. Para detectar bloqueio ou exclusão antes da expiração, é necessário um endpoint de status não-consumível do AuthTool; não usar `onLogin` automaticamente na inicialização para uma key de ativação única.
