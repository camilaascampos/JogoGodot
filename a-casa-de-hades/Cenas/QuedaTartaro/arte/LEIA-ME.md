# Arte da Queda no Tártaro

Tudo que não tiver arquivo aqui usa **arte provisória gerada em código** (`scripts/core/FallArt.gd`). Para trocar, salve um PNG nesta pasta
com o nome do id — nenhum script muda. A imagem é esticada para o tamanho do objeto (a colisão
não depende da imagem).

## Sprites animadas (grade)
Coloque colunas e linhas no nome, antes do `.png`:

| arquivo                     | significado |
|-----------------------------|-------------|
| `party.png`                 | imagem estática |
| `party_4x2.png`             | grade com 4 colunas e 2 linhas = 8 quadros (esquerda→direita, cima→baixo) |
| `party_6x1.png`             | faixa horizontal de 6 quadros |
| `party_4x2_12fps.png`       | idem, a 12 quadros/s (padrão: 8) |

### Ou uma pasta com um PNG por quadro
Crie uma **pasta** em `arte/` com o nome do id e ponha os quadros dentro (ordem alfabética/numérica):
`arte/spitter/spit_00.png, spit_01.png, spit_02.png...` (use 01, 02... ou 1, 2, 10: ambos funcionam).
Para mudar a velocidade, nomeie a pasta `party_12fps`. Todos os quadros com o mesmo tamanho.

### Pasta com as 8 direções (PixelLab "rotações")
Por padrão (`TREAT_DIRECTIONS_AS_VIEWS := false` em `scripts/core/FallArt.gd`) uma pasta com `south.png, east.png...`
toca como animação, uma imagem após a outra (ordem alfabética), como qualquer pasta de quadros.
Com `true`, vira 8 vistas fixas: o jogador usa `south` parado, `south-west`/`south-east` ao mover
(`FACING_*` no topo de `scripts/core/FallParty.gd`).

Todos os quadros da grade têm que ter o mesmo tamanho. O sprite sempre aparece no tamanho do objeto.

## IDs
| id                              | tamanho do objeto | uso |
|---------------------------------|-------------------|-----|
| party (pasta de 8 direções)     | altura 96         | Percy + Annabeth caindo |
| party_slash / party_shield / party_jet | idem       | trocam o sprite enquanto usa espada / escudo / jato (também 8 direções) |
| rock_small, rock_large          | 56x56, 120x110    | rochas |
| creature_small / mid / brute    | 64x56, 96x88, 150x130 | criaturas (espada) |
| creature_giant                  | 360x240           | guardião (só jato, 3 acertos) |
| spitter (pasta de quadros)      | 120x72            | verme cuspidor; 11 quadros em repetição; arte virada para a direita, o jogo espelha na parede direita |
| poison                          | 100x60            | veneno (aponta para a direita) |
| barrier                         | 1152x64           | rocha maciça (só jato) |
| river                           | 1152x320          | rio do final |
| portrait_<annabeth\|percy>_<neutral\|alert\|worried\|smirk> | 56x56 | retratos (se vier em grade, usa só o 1º quadro) |
| shaft_<far\|mid\|near>_<0,1,2,3> | 1152x1152 por segmento | fundo (veja abaixo) |

## Fundo
- Arquivos: `shaft_far_0.png`, `shaft_far_1.png`, `shaft_mid_0.png`, `shaft_near_0.png`... Podem ser animados
  (`shaft_mid_0_4x1.png`). Cada um é esticado para 1152x1152 e repetido na vertical: **borda de cima e de baixo
  precisam se encaixar**. Com mais de uma variante por camada, elas se alternam aleatoriamente.
- Não precisa ter as 3 camadas: camada sem arquivo continua usando o fundo provisório. Para desligar uma camada,
  ponha `"enabled": false` em `scripts/data/FallBackground.gd`.
- Em `scripts/data/FallBackground.gd` você muda também: velocidade de cada camada (`factor`), transparência, ordem,
  criar camadas novas e a cor de trás (`COLOR`). `factor` 0 = fundo parado.
- Se sua arte NÃO for pixel art, mude `PIXEL_ART` para `false` em `scripts/core/FallArt.gd` (liga a suavização).
