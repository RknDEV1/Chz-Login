# Revisão do Chz-Login

## Correções aplicadas

A tela agora normaliza a key antes do envio, impede submissões duplicadas, desabilita os controles enquanto a validação está em andamento, mostra indicador de carregamento e exibe o estado de erro diretamente na tela. Após falha, os controles são reabilitados e a key inválida não é salva pelo `CHZAuthManager`.

O layout foi ajustado para reservar espaço para a mensagem de estado em telas compactas, mantendo o visual escuro CHZ PRIV, os detalhes vermelhos e o suporte a tamanhos diferentes de tela.

Foi adicionado um `.gitignore` para impedir o versionamento de `CHZSecrets.h`, certificados, perfis de provisionamento e artefatos de build.

## Validação

A revisão foi estática em ambiente Linux. Não foi possível executar Xcode, compilar para iOS, assinar, instalar em dispositivo ou validar uma resposta real do AuthTool. O `CHZ_API_TOKEN` não está incluído. A compilação e o teste final precisam ser feitos em um ambiente macOS/Xcode autorizado.

## Segurança

O pacote não deve conter tokens, AES keys, Public API keys, certificados ou chaves privadas. O secret real deve ser fornecido somente pelo mecanismo privado do ambiente de build.

## Ajuste baseado na referência visual

A tela foi ajustada para reproduzir a composição enviada: fundo preto, marca CHZ PRIV ampliada em telas grandes, cartão central alto com borda e glow vermelho, campo de key, botão OBTER DID, botão ENTRAR, suporte e botão circular do Discord. O layout continua responsivo e mantém uma versão compacta para telas menores.

## Correção do fechamento na abertura

A validação automática de uma key salva foi removida de `viewDidLoad`. A tela agora permanece aberta e limpa até o usuário tocar em `ENTRAR`. O `dismiss` continua ocorrendo somente no callback de sucesso do login iniciado pelo usuário. Isso evita que uma key antiga do Keychain faça a tela desaparecer imediatamente ao iniciar.

## Assets visuais fornecidos

Foram adicionados `Resources/CHZPrivLogo.png` e `Resources/discord.png` a partir dos arquivos compartilhados. A tela tenta carregar esses assets pelo nome; caso a imagem não esteja incluída no bundle do target, mantém um fallback textual para a logo e um ícone sistêmico para suporte. Para obter o visual da referência, os dois recursos precisam ser adicionados ao target/bundle no Xcode.
