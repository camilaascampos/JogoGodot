# Organização do projeto

Regra de ouro: **cada cena guarda tudo que é só dela** (cena, scripts e arte). O que várias cenas
usam fica em `Assets/` ou `Characters/`.

```
a-casa-de-hades/
├── addons/                    plugins (turnbasedcombat, gdrama). Não mexer.
├── Assets/                    arte/fonte COMPARTILHADA, sem código
│   ├── Fontes/                fontes (Pixelify Sans, Silkscreen)
│   └── Sprites/               pacotes de sprites de terceiros (ex.: fantasmas CraftPix)
├── Cenas/                     UMA pasta por cena
│   ├── CenaInicio/            cutscene inicial (gdrama)
│   ├── EntreBosses/           plataforma entre os bosses
│   ├── QuedaTartaro/          queda no Tártaro (ver LEIA-ME.md dela)
│   └── Batalha/               batalha em turnos (Battle3v2.tscn + BattleChars/<nome>/Battle.tscn)
├── Characters/                DADOS (.tres) usados pelo combate: Player, Enemy, Skills, Effects
├── Scripts/                   scripts soltos que não pertencem a nenhuma cena
└── project.godot
```

Dentro de cada pasta de cena:

```
Cenas/<Cena>/
├── <cena>.tscn      a cena (o arquivo que se abre/roda)
├── scripts/         todo o código da cena (pode ter subpastas)
├── arte/            só imagens/animações da cena (uma pasta por sprite quando tiver vários quadros)
└── LEIA-ME.md       opcional: como a cena funciona
```

Convenções
- Cena nova: crie `Cenas/NomeDaCena/` com `scripts/` e `arte/`. Arte usada por mais de uma cena vai para `Assets/`.
- **Nunca** deixe script embutido na cena ("Make built-in"): ele vira uma cópia e deixa de acompanhar o `.gd`.
- **Nunca** copie uma pasta de cena para outro lugar (dois `class_name` iguais quebram o projeto).
- Mover/renomear arquivos: faça sempre **dentro do editor do Godot** (painel FileSystem), que atualiza os caminhos sozinho.
- `Characters/` e a pasta `BattleChars/<nome>/` precisam casar com o `Name` da espécie (o combate monta o caminho
  `Cenas/Batalha/BattleChars/<Name>/Battle.tscn`).
