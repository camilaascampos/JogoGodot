# Queda no Tártaro — guia rápido

**Rodar sozinha:** abra `Cenas/QuedaTartaro/queda_tartaro.tscn` e aperte F6. Marque `DebugKeys` no nó raiz
para: F1–F8 pular de fase · H mostrar colisões · G invencível.

**Controles:** ← → / A D mover · Z (ou J) espada · X (ou K) escudo, segurar · C (ou L) jato de água.
As habilidades são liberadas pelo tutorial (Annabeth). Dicas de tecla aparecem só no momento certo.

**Integração**
- Entrada: antes de abrir a cena, `FallState.set_entry({"start_phase": 0})` (opcional).
- Saída: exporte `NextScenePath` no nó raiz, ou mude `FallState.next_scene`. Padrão: EntreBosses
  (só um caminho; se o arquivo não existir aparece uma tela de fim). Resultado em `FallState.result`
  e sinal `sequence_finished`.

**Balanceamento:** tudo em `scripts/data/FallTimeline.gd` (tempos, velocidades, perigos, falas) e `scripts/hazards/FallHazard.gd` (KINDS).
**Estrutura:** `scripts/` (core: Director, Party, Camera, State, FallArt · hazards · world · ui · data) e `arte/` (só imagens).

**Arte e fundo:** coloque PNGs em `arte/` (estáticos, grade, pasta de quadros ou pasta de 8 direções). Veja `arte/LEIA-ME.md`.
Camadas do fundo: `scripts/data/FallBackground.gd`.
