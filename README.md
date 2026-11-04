# PROJECT: DEADLIGHT

Original cartoon 3D twin-stick shooter, Godot **4.3 stable**, GDScript,
Compatibility renderer (WebGL 2). Captain Tranco defends a coastal military base.

Play: https://mariomarques01.github.io/gamewoood/

Open `project.godot` with Godot 4.3 and run the configured `scenes/main.tscn`.
Desktop: WASD/arrows, hold left mouse to aim/fire, Space to jump, Escape to pause.
Mobile: drag the left stick to move and the right stick to aim/fire simultaneously.
Use the arrow action with a third finger while moving/aiming.
Select pistol/machine gun with 1/2 or Q; R reloads. On mobile, tap the circular weapon button on the right with a third finger. The pistol carries 12 rounds; the
machine gun carries 24. Empty magazines reload automatically. Stand near the current green objective
for three seconds while no alien is within five metres. Complete arsenal,
helipad and communications to win. Restart is available after victory/defeat.

## Validation and publication

See [weapons and stage finale](docs/ARSENAL_FINALE.md), [tactical combat and references](docs/ARCADE_IMPACT.md), [audio and credits](docs/AUDIO.md), [landscape combat](docs/LANDSCAPE_COMBAT.md), [compact HUD and research](docs/COMPACT_HUD_RESEARCH.md), [cartoon polish](docs/CARTOON_POLISH.md), [HUD and jump changes](docs/HUD_AND_JUMP.md), [recovery diagnosis](docs/RECOVERY.md) and [architecture/status](docs/ARCHITECTURE.md).
Run `tools/validate.sh --export` with official Godot 4.3, an OpenGL display or Xvfb,
then `python3 tests/web_smoke.py --directory build/web` with Playwright installed.
PRs run the same checks. A single workflow `.github/workflows/deploy-web.yml`
deploys main only after runtime, export and browser checks pass.

This is a playable procedural prototype. Real iPhone/Safari and Android device
validation, native signing/exports, profiling and production art remain necessary.

Combat supplies drop every third elimination. Ten quick kills trigger a four-second
TRANCO TOTAL boost. Pause to see the complete objective list and elimination count.

Play in landscape. Portrait pauses the game and asks you to rotate the device.
Enemy defeats burst into fragments and alien blood. Collect credit tokens and
complete the optional 12-alien bonus objective; credits are recorded after a run.

Audio: quiet ambient music plus curated combat/interaction effects. The first touch
or key activates browser audio. Adjust MUSICA/EFEITOS or mute in pause; settings persist.

Shoot orange energy canisters twice, then leave their warning ring. Blasts can
chain and walls block them. Combos show remaining time; TRANCO TOTAL lights a cyan
aura. Hit aliens briefly show health, and supply attraction respects walls.

Completing all three objectives celebrates the Captain and opens a saved results
report with time, eliminations, medals and completion credits. Replay starts a new
run; a finished run never grants its reward twice.

## Instalar como aplicativo (PWA)

Depois da publicação, abra https://mariomarques01.github.io/gamewoood/:

- **Android / Chrome:** menu → **Instalar aplicativo** ou **Adicionar à tela inicial**.
- **iPhone / iPad / Safari:** Compartilhar → **Adicionar à Tela de Início**.
- **Computador / Chrome ou Edge:** use o ícone de instalação na barra de endereço.

O aplicativo abre em modo independente e solicita orientação horizontal quando
suportada pelo sistema. No iOS, gire o dispositivo manualmente, se necessário.
A primeira abertura exige internet: aguarde o jogo carregar e o cache terminar.
Depois, o jogo pode iniciar sem conexão. O navegador pode remover o cache quando
falta espaço ou os dados do site são apagados; nesse caso, abra novamente online.

O preset Web ativa o PWA nativo do Godot. `tools/validate.sh --export` também
executa `tools/prepare_pwa.py build/web`, que completa o manifesto e prepara o
cache integral do jogo, incluindo a abertura pelo subdiretório do GitHub Pages.
Para exportações manuais, execute esse comando depois do export do Godot.
HTTPS é obrigatório em produção; localhost funciona para desenvolvimento.

`python3 tests/web_pwa.py --directory build/web` verifica os metadados de
instalação no Chromium e executa o jogo com a rede desativada, tanto no endereço
do diretório quanto em `index.html`. Esse teste também roda no CI antes do deploy.

## XP, Fúria Tranco e hordas

Elimine alienígenas para ganhar 10 XP por inimigo. Com 180 XP, a **Fúria Tranco**
ativa por 10 segundos: dano triplicado, tiros mais rápidos, movimento 50% mais
rápido e munição ilimitada. A barra no topo mostra a próxima ativação e sua
contagem regressiva. Cada ativação aumenta a exigência de XP; reiniciar zera a
progressão da partida.

As hordas chegam a 24 alienígenas e incluem corredores e brutamontes, além dos
soldados e atiradores. As eliminações deixam sangue mais espalhado e persistente.
O visual inclui novas fontes locais e detalhes de rua. Consulte
[XP e hordas](docs/XP_AND_HORDES.md) para regras, limites e validação.


## HUD e controles da referência

Retrato do Capitão e vida ficam no canto superior esquerdo, com a carga da Fúria
em cinco segmentos logo abaixo. Objetivo, créditos e munição ocupam o topo; a
engrenagem abre pausa/configurações. O selo do retrato acompanha o nível de
Fúria alcançado na partida.

No celular, arraste o controle esquerdo para mover e o direito para mirar/atirar.
O botão circular pequeno à direita alterna pistola e metralhadora; o botão
amarelo acima da mira salta. Ambos aceitam um terceiro dedo enquanto os dois
controles continuam ativos. Teclado e mouse mantêm os atalhos existentes.

## Bairro 1 expandido

O mapa jogável mede 148 × 128 metros e segue a disposição da referência:
arsenal, base do capitão e heliponto ao norte; oficina, quartel general e centro
de suprimentos ao sul. Ruas asfaltadas conectam os seis quarteirões. As áreas
internas são pavimentadas, com grama restrita aos canteiros cercados das árvores.
O perímetro tem muralhas, torres e portão; a costa inclui falésias e cachoeiras.
Abra **MAPA** (ou **M**) para consultar a visão geral 3D e a legenda. O combate
fica pausado até voltar ao jogo. As três missões continuam sendo arsenal,
heliponto e comunicações, agora nas novas posições do bairro.

A geometria estática é unida em malhas por regiões de 16 m, preservando o controle
de sombras e a visibilidade local. A câmera mantém o personagem enquadrado e
recupera a posição após grandes deslocamentos. `tests/rendering_smoke.gd` verifica
21 pontos do bairro; `tests/web_rendering.py` verifica pixels e mudanças de quadro
em 12 regiões no WebKit com DPR 3, incluindo partículas e sangue de combate.
