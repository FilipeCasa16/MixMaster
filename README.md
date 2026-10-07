#  MixMaster

Trabalho de **DSDM** — **Filipe Casadei** e **Laura L. Faccin**.

![Flutter](https://img.shields.io/badge/Flutter-3.32%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8%2B-0175C2?logo=dart&logoColor=white)
![API](https://img.shields.io/badge/API-TheCocktailDB-E29C2F)

---

## Descrição do Projeto

O **MixMaster** é um aplicativo de drinks feito em **Flutter**. Nele é possível descobrir drinks, buscar pelo nome, **filtrar por ingredientes**, sortear um drink de acordo com o humor e ver a receita completa.

Todos os drinks, ingredientes, imagens, medidas e receitas vêm de uma API pública chamada TheCocktailDB pelo link "https://www.thecocktaildb.com/documentation". Nenhum drink é escrito "na mão" no código.

---

## Funcionalidades

| Tela | O que faz |
|---|---|
|  **Home** | Lista drinks aleatórios, alternando entre cards. Tem busca por nome, filtro por ingredientes e botão **Ver mais** no final da página para visualizar uma continuação da lista aleatória de drinks. |
|  **Ingredientes** | Mostra todos os ingredientes com imagem e busca. Ao tocar em um, abre um popup com detalhes e o botão **Ver Drinks com X**, que leva para a Home já filtrada |
|  **Sorteio** | Escolha seu humor e sorteie um drink. A tela de detalhes do drink sorteado abre automaticamente |
|  **Detalhes** | Mostra a Imagem, categoria, copo, ingredientes com medidas, modo de preparo de cada drink |

**Humores do sorteio:**  Leve e Refrescante ·  Festa! ·  Relaxado ·  Forte e Intenso ·  Surpreenda-me!

---

##  API Utilizada

O app usa a **[TheCocktailDB](https://www.thecocktaildb.com/documentation)**, uma API pública de coquetéis.

-  **Gratuita:** funciona com a chave de testes `1`, **sem cadastro e sem configuração**.
-  **Precisa de internet** para carregar drinks, imagens e a tradução.
- 🇺🇸 Os dados vêm **em inglês**. O app traduz para português usando o serviço gratuito [MyMemory](https://mymemory.translated.net/).

---

##  Pré-requisitos

Antes de começar, instale:

- **Git**
- **Flutter SDK 3.32 ou superior** (já inclui o Dart)
- **Visual Studio Code** com as extensões **Flutter** e **Dart**
- **Google Chrome** (para rodar na web) *ou* um emulador Android

<details>

 Abra um terminal **novo** e confira:

```bash
flutter --version
flutter doctor
```

> [!IMPORTANT]
> A versão precisa ser **Flutter 3.32+** (Dart 3.8+). Se estiver abaixo, rode `flutter upgrade`.

</details>

---

##  Como Executar

### Primeiro Passo: Clonar o Repositório

```bash
git clone "https://github.com/FilipeCasa16/MixMaster.git"
cd mixmaster
```

Depois, abra a pasta `mixmaster` no **Visual Studio Code**.

### Segundo Passo: Instalar as Dependências

No terminal, dentro da pasta do projeto rode:

```bash
flutter pub get
```

> [!NOTE]
> O projeto usa **uma única dependência**, o pacote `http`, que já deve estar no `pubspec.yaml`. Se ela não estiver lá, instale com `flutter pub add http`.

### Terceiro Passo: Conferir a Logo e o `pubspec.yaml`

O app carrega a logo `assets/images/mixmaster-logo.png` (fora da pasta `lib`). No `pubspec.yaml`, confira se existem estas duas partes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

> [!WARNING]
> Sem o arquivo da logo ou sem a linha `assets:`, a Home mostra um erro de "asset não encontrado".

O ícone do aplicativo para Android, iOS e instalação web é gerado a partir de
`mixmaster/assets/images/mixmaster-app-icon.png`. Para recriar os tamanhos
nativos depois de alterar a imagem, rode dentro da pasta `mixmaster`:

```bash
dart run flutter_launcher_icons
```

### Quarto Passo: Executar o App

```bash
flutter run -d chrome
```

O app abre sozinho no navegador. Para outros dispositivos, use `flutter devices` para listar e `flutter run -d <nome>` (por exemplo, `windows`, `linux`, `macos`), ou apenas `flutter run` com um emulador Android aberto.

###  Como saber se funcionou

Ao abrir, a Home mostra os drinks com imagem. Teste também: **Ver mais**, o **filtro de ingredientes**, a aba **Ingredientes**, o **Sorteio** (abre os detalhes do drink sozinho) e a tradução na tela de detalhes.


---

<br>


##  Desenvolvedores

**Filipe Casadei** e **Laura L. Faccin**.

---

<sub>Dados de drinks fornecidos pela <a href="https://www.thecocktaildb.com/">TheCocktailDB</a> · Tradução por <a href="https://mymemory.translated.net/">MyMemory</a></sub>
