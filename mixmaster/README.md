# MixMaster

Aplicativo Flutter de descoberta de drinks, usando a API
[TheCocktailDB](https://www.thecocktaildb.com/api.php).

## Cobertura da API

O app reúne os drinks devolvidos pelas buscas de todas as letras e cruza os
ingredientes localmente, pois o filtro de ingrediente da chave de teste pode
retornar apenas parte dos resultados. A lista oficial de ingredientes dessa
chave também é limitada a 100 itens; o app a complementa com os ingredientes
encontrados nas receitas disponíveis. A TheCocktailDB informa que o banco
completo requer uma chave de produção Premium.

## Idioma e medidas

As instruções, ingredientes e descrições dos drinks são traduzidos para
português sob demanda pelo serviço gratuito MyMemory. As medidas reconhecidas
também mostram equivalências aproximadas em mililitros; as medidas originais
da API são preservadas para consulta.
