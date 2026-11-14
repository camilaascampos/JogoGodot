class_name FallBackground
## Configuração do fundo (poço do Tártaro). Edite aqui para mudar camadas, velocidades e cor.
##
## Cada camada usa imagens art/shaft_<name>_<n>.png (n = 0, 1, 2...), estáticas OU em grade
## (ex.: shaft_mid_0_4x1.png). Cada imagem é esticada para 1152 x 1152 e repetida na vertical,
## então a borda de cima e a de baixo precisam se encaixar (sem emenda). Se houver mais de uma
## variante, elas se alternam aleatoriamente. Sem nenhum arquivo, usa o fundo provisório.
##
##   name         : parte do nome do arquivo (far / mid / near) — pode criar nomes novos
##   factor       : velocidade de rolagem relativa à queda (0.25 = longe e lento, 1.5 = perto e rápido,
##                  0 = parado, para um fundo fixo)
##   max_variants : quantos arquivos _0, _1, _2... procurar
##   z            : ordem de desenho (menor = mais ao fundo; o grupo fica em 2+)
##   alpha        : transparência da camada
##   enabled      : false desliga a camada

## Cor atrás de tudo (aparece onde as camadas forem transparentes).
const COLOR := Color(0.015, 0.02, 0.05)

const LAYERS := [
	{ "name": "far", "factor": 0.25, "max_variants": 4, "z": -30, "alpha": 1.0, "enabled": true },
	{ "name": "mid", "factor": 1.0, "max_variants": 4, "z": -20, "alpha": 1.0, "enabled": true },
	{ "name": "near", "factor": 1.5, "max_variants": 4, "z": -10, "alpha": 1.0, "enabled": true },
]
