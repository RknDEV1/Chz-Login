# Diagnóstico de autenticação

A documentação pública do AuthTool descreve endpoints separados para criar keys de ativação única, criar keys de múltiplas ativações, resetar uma key e consultar seus detalhes. A configuração do app usa o `CHZ_API_TOKEN` como credencial do package; o valor do secret não é legível neste ambiente.

A validação atual exige que `getKey` seja preenchido imediatamente. Como a APIClient também expõe `getPackageDataWithKey:`, a próxima correção deve usar esse retorno oficial como confirmação adicional, sem exigir que `getPackageName` esteja disponível no mesmo instante.
