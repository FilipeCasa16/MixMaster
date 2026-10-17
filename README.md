# MixMaster

Trabalho de **DSDM** — **Filipe Casadei** e **Laura L. Faccin**.

![Flutter](https://img.shields.io/badge/Flutter-3.32%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8%2B-0175C2?logo=dart&logoColor=white)
![API](https://img.shields.io/badge/API-TheCocktailDB-E29C2F)

---

## Descrição do Projeto

O **MixMaster** é um aplicativo de drinks feito em **Flutter**. Nele é possível descobrir drinks, buscar pelo nome, filtrar por ingredientes e por tipo, sortear um drink de acordo com o humor, ver a receita completa e salvar seus drinks favoritos em uma conta.

Todos os drinks, ingredientes, imagens, medidas e receitas vêm de uma API pública chamada TheCocktailDB pelo link "https://www.thecocktaildb.com/documentation". 

---

## Funcionalidades

| Tela | O que faz |
|---|---|
| **Home** | Lista drinks aleatórios, alternando entre cards. Tem busca por nome, filtro por ingredientes, filtro por tipo e botão **Ver mais** no final da página para visualizar uma continuação da lista aleatória. |
| **Ingredientes** | Mostra todos os ingredientes com imagem e busca. Ao tocar em um, abre um popup com detalhes e o botão **Ver Drinks com X**, que leva para a Home já filtrada |
| **Sorteio** | Escolha seu humor e sorteie um drink. A tela de detalhes do drink sorteado abre automaticamente |
| **Detalhes** | Mostra a imagem, categoria, copo, ingredientes com medidas, modo de preparo de cada drink e o botão de favoritar (coração) |
| **Conta** | Criar conta ou entrar com e-mail e senha. Logado, mostra o perfil e os **drinks curtidos**, com opção de sair da conta |

**Humores do sorteio:** Leve e Refrescante · Festa! · Relaxado · Forte e Intenso · Surpreenda-me!

---

## Conta e Favoritos

- Para favoritar um drink é preciso **estar logado**. Se não estiver, o app avisa e oferece o botão **Entrar**.
- A conta é **local**: o e-mail e a senha ficam salvos apenas no próprio aparelho (ou navegador), em um banco **SQLite**. Não existe servidor.
- A senha **nunca é guardada em texto puro** (é protegida com PBKDF2-HMAC-SHA256 e *salt*) e precisa ter **no mínimo 8 caracteres**.
- Depois de fechar e abrir o app, o login e os favoritos continuam salvos.
- Não há recuperação de senha: se os dados do app (ou do navegador) forem apagados, as contas e os favoritos também são.

---

## API Utilizada

O app usa a **[TheCocktailDB](https://www.thecocktaildb.com/documentation)**, uma API pública de coquetéis.

- **Gratuita:** funciona com a chave de testes `1`, **sem cadastro e sem configuração**.
- **Precisa de internet** para carregar drinks, imagens e a tradução.
- Os dados vêm **em inglês**. O app traduz para português usando o serviço gratuito [MyMemory](https://mymemory.translated.net/).

---

## Pré-requisitos

Antes de começar, instale:

- **Git**
- **Flutter SDK 3.32 ou superior** (já inclui o Dart)
- **Visual Studio Code** com as extensões **Flutter** e **Dart**
- **Google Chrome** (para rodar na web) *ou* um emulador Android
- **Somente no Linux:** a biblioteca do SQLite, com `sudo apt-get install -y libsqlite3-0 libsqlite3-dev`

<details>
<summary><b>Conferir a instalação do Flutter</b></summary>

<br>

Abra um terminal **novo** e confira:

```bash
flutter --version
flutter doctor
```

> [!IMPORTANT]
> A versão precisa ser **Flutter 3.32+** (Dart 3.8+). Se estiver abaixo, rode `flutter upgrade`.

</details>

---

## Como Executar

### Primeiro Passo: Clonar o Repositório

```bash
git clone "https://github.com/FilipeCasa16/MixMaster.git"
cd MixMaster
```

Depois, abra a pasta `MixMaster` no **Visual Studio Code**.

### Segundo Passo: Instalar as Dependências

No terminal, dentro da pasta do projeto rode:

```bash
flutter pub get
```

> [!NOTE]
> O projeto usa os pacotes da tabela abaixo, que já devem estar no `pubspec.yaml`. Se algum estiver faltando, instale todos de uma vez com:
> `flutter pub add http sqflite sqflite_common_ffi sqflite_common_ffi_web cryptography path`

| Pacote | Para que serve |
|---|---|
| `http` | Comunicação com a API de drinks e com o serviço de tradução |
| `sqflite` | Banco de dados local (Android, iOS e macOS) |
| `sqflite_common_ffi` | Banco de dados local no Windows, Linux e macOS |
| `sqflite_common_ffi_web` | Banco de dados local no navegador (Chrome) |
| `cryptography` | Proteção das senhas (hash) |
| `path` | Define o local do arquivo do banco de dados |

### Terceiro Passo: Conferir a Logo e o `pubspec.yaml`

O app carrega a logo `assets/images/mixmaster-logo.png` (fora da pasta `lib`). No `pubspec.yaml`, confira se existem estas duas partes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0
  sqflite: ^2.4.4
  sqflite_common_ffi: ^2.4.3
  sqflite_common_ffi_web: ^1.2.0
  cryptography: ^2.9.0
  path: ^1.9.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

> [!WARNING]
> Sem o arquivo da logo ou sem a linha `assets:`, a Home mostra um erro de "asset não encontrado".

**Somente para rodar na web (Chrome):** o banco de dados precisa de dois arquivos dentro da pasta `web/` (`sqlite3.wasm` e `sqflite_sw.js`). Se eles já estiverem no repositório, não precisa fazer nada. Se não estiverem, gere com:

```bash
dart run sqflite_common_ffi_web:setup
```

> [!IMPORTANT]
> Sem esses dois arquivos, o app no Chrome mostra a tela de erro **"Não foi possível acessar os dados salvos"**.

O ícone do aplicativo para Android, iOS e instalação web é gerado a partir de
`mixmaster/assets/images/mixmaster-app-icon.png`. Para recriar os tamanhos
nativos depois de alterar a imagem, rode dentro da pasta `mixmaster`:

```bash
dart run flutter_launcher_icons
```

<details>
<summary><b>Configuração do ícone no <code>pubspec.yaml</code> (exemplo)</b></summary>

<br>

O comando acima usa o pacote `flutter_launcher_icons`, que fica em `dev_dependencies`, e a configuração `flutter_launcher_icons:` no `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/mixmaster-app-icon.png"
  web:
    generate: true
    image_path: "assets/images/mixmaster-app-icon.png"
```

Depois de editar, rode `flutter pub get` antes de `dart run flutter_launcher_icons`.

</details>

### Quarto Passo: Executar o App

```bash
flutter run -d chrome --web-port=5000
```

O app abre sozinho no navegador. Para outros dispositivos, use `flutter devices` para listar e `flutter run -d <nome>` (por exemplo, `windows`, `linux`, `macos`), ou apenas `flutter run` com um emulador Android aberto.

> [!TIP]
> Na web, a conta e os favoritos ficam guardados no navegador, separados por endereço (incluindo a porta). Por isso o comando usa uma porta fixa (`--web-port=5000`): sem ela, o Flutter escolhe uma porta nova a cada execução e a conta criada antes pode parecer ter sumido.

### Como saber se funcionou

Ao abrir, a Home mostra os drinks com imagem. Teste também: **Ver mais**, os filtros de **tipo de drink** (Todos, Alcoólicos e Sem álcool) e de **ingredientes**, a aba **Ingredientes**, o **Sorteio** (abre os detalhes do drink sozinho) e a tradução na tela de detalhes.

Na aba **Conta**, crie uma conta, favorite um drink pelo coração na tela de detalhes e confira se ele aparece em **Drinks curtidos**.


---

<br>


## Desenvolvedores

**Filipe Casadei** e **Laura L. Faccin**.

---

<sub>Dados de drinks fornecidos pela <a href="https://www.thecocktaildb.com/">TheCocktailDB</a> · Tradução por <a href="https://mymemory.translated.net/">MyMemory</a></sub>
