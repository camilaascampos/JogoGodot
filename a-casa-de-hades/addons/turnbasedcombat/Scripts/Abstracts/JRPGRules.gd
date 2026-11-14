class_name JRPGRules
## Números globais do combate. Mexa aqui para balancear sem caçar no código.

## Dano variável: sorteio entre 90% e 110% do dano base.
const DAMAGE_VARIANCE_MIN := 0.9
const DAMAGE_VARIANCE_MAX := 1.1
## Acerto crítico: chance inicial de 10%, causa 1,5x o dano.
const CRIT_CHANCE := 0.10
const CRIT_MULTIPLIER := 1.5
## Esquiva: cada ponto de Speed da espécie dá 0,5% de chance (máximo 40%).
const DODGE_PER_SPEED := 0.5
const DODGE_CAP := 40.0
## Resistência: se o elemento do ataque == Strength da espécie, o dano cai 25%.
const RESIST_REDUCTION := 0.25
