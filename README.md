# PROJECT: DEADLIGHT

Original cartoon 3D twin-stick shooter, Godot **4.6.3 stable**, GDScript,
Compatibility renderer (WebGL 2). Captain Tranco defends a coastal military base.

Play: https://mariomarques01.github.io/gamewoood/

Open `project.godot` with Godot 4.6.3 and run the configured `scenes/main.tscn`.
Desktop: WASD/arrows, hold left mouse to aim/fire, Space to jump, Escape to pause.
Mobile: drag the left stick to move and the right stick to aim/fire simultaneously.
Use the arrow action with a third finger while moving/aiming.
Select pistol/machine gun with 1/2 or Q; R reloads. On mobile, tap the circular weapon button on the right with a third finger. The pistol carries 12 rounds; the
machine gun carries 24. Empty magazines reload automatically. Stand near the current green objective
for three seconds while no alien is within five metres. Complete arsenal,
helipad and communications to win. Restart is available after victory/defeat.

## Validation and publication

See [weapons and stage finale](docs/ARSENAL_FINALE.md), [tactical combat and references](docs/ARCADE_IMPACT.md), [audio and credits](docs/AUDIO.md), [landscape combat](docs/LANDSCAPE_COMBAT.md), [compact HUD and research](docs/COMPACT_HUD_RESEARCH.md), [cartoon polish](docs/CARTOON_POLISH.md), [HUD and jump changes](docs/HUD_AND_JUMP.md), [recovery diagnosis](docs/RECOVERY.md) and [architecture/status](docs/ARCHITECTURE.md).
Run `tools/validate.sh --export` with official Godot 4.6.3, an OpenGL display or Xvfb,
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

As hordas chegam a 20 alienígenas e incluem corredores e brutamontes, além dos
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
em 13 casos de regiões/recuperação no WebKit com DPR 3, incluindo partículas e sangue de combate.

Na versão **0.11.0**, o PWA usa Godot **4.6.3** e os alienígenas e efeitos também
usam malhas comuns, sem MultiMesh na cena ativa. A versão instalada aparece no
menu de pausa. A instalação de uma atualização revalida os arquivos pela rede;
o teste `tests/web_update.py` simula uma versão anterior com cache HTTP ainda
válido e verifica a atualização, a preservação dos dados da origem e o modo offline.
A verificação WebKit inclui duas voltas contínuas pelo heliponto com combate ativo.


## Áudio de combate — 0.12.0

A trilha é **Battle of the Void (Loop)**, de Marcelo Fernandez: 158 segundos de
música de ação, com loop musical e volume condicionado. A pistola usa gravações
de uma 1911 e a metralhadora de uma Carl Gustav M45, com três variações reais por
arma e recargas distintas. Os alienígenas vocalizam ao se aproximar, preparar
ataques, receber dano e morrer. Sons distantes são descartados; até três vozes
de criaturas dividem as 12 vozes do mixer, com prioridade para disparos e interface.
Créditos e licenças: [assets/audio/CREDITS.md](assets/audio/CREDITS.md).
O limite de inimigos simultâneos foi reduzido para **20**.

## Tela inicial e formato horizontal — 0.13.0

A abertura usa a imagem fornecida pelo usuário, sem alterações. **Jogar** cria a
partida; nenhum mapa, inimigo ou cronômetro roda atrás do menu. **Configurações**
abre os volumes de música/efeitos e o mute, usando as mesmas preferências salvas
da partida. Arsenal, Upgrades e Conquistas permanecem sem ação nesta versão.

O canvas permanece em 16:9, com enquadramento horizontal e áreas de toque alinhadas
à imagem. Em celulares e no PWA instalado, a orientação solicitada é horizontal.
Ao tocar em Jogar, a versão web tenta tela cheia e o bloqueio de orientação quando
o navegador permite. Navegadores que não permitem esse bloqueio apresentam o jogo
horizontal com barras de enquadramento, inclusive com o aparelho na vertical;
a partida não fica presa na antiga tela de rotação.

`tests/start_menu_smoke.gd` verifica imagem, botões, sliders por toque,
persistência e entrada no jogo em uma janela vertical. `tests/web_smoke.py`
compara os pixels da abertura com a imagem original e testa o fluxo em desktop,
mobile e retrato. `--menu-only` executa apenas esse fluxo inicial.


## Horizontal obrigatório e tela inteira — 0.14.0

A apresentação não fica mais centralizada com barras em uma janela vertical.
O adaptador web gira o canvas inteiro 90° antes do primeiro frame quando a janela
está na vertical, usa uma superfície de renderização horizontal e ocupa toda a
área disponível. Ao girar o celular, o canvas se reajusta, mantendo a orientação
horizontal e sem bordas. Toque, arraste e mouse passam pela transformação inversa;
as áreas clicáveis acompanham a imagem e os controles da partida.

A versão nativa solicita `SCREEN_SENSOR_LANDSCAPE`, permitindo as duas posições
horizontais. O menu preenche a superfície disponível com todos os botões visíveis.
A arte inicial foi editada para remover o aviso vermelho do Arsenal.

O adaptador é incorporado em `tools/prepare_pwa.py`. Os dois pontos de entrada de
coordenadas do runtime Godot 4.6.3 são verificados durante a exportação; a build
falha se a versão do template mudar esses pontos, evitando publicar toques com
coordenadas incorretas. Os testes web cobrem retrato, horizontal, giro durante a
partida, preenchimento da tela e interações após o giro.

## Defesa, arsenal e progresso — 0.15.0

- Três ondas finitas de 8, 12 e 16 alienígenas, com composição variada, cadência crescente e oito segundos de intervalo. O limite continua em 20 inimigos simultâneos. Depois da terceira onda, não há reaparecimento infinito; os três objetivos continuam sendo a condição de vitória.
- Cada onda concluída concede 25/50/75 créditos, cura 5 pontos e repõe as duas armas. As recompensas entram no relatório e são salvas ao terminar a partida, inclusive na derrota. A conclusão das ondas é opcional: capturar os objetivos antes continua sendo uma estratégia válida.
- Arsenal e Upgrades permitem escolher a arma inicial e comprar até três níveis de dano (+10% por nível) e recarga (-10% por nível), separadamente para cada arma. Preços por nível: 75/150/225 créditos. As duas armas permanecem disponíveis durante o combate.
- Conquistas apresenta os recordes já existentes e a melhor quantidade de ondas concluídas. O resultado agora oferece retorno ao menu para gastar os créditos. Compras e equipamento são salvos imediatamente com substituição do arquivo temporário; falhas não descontam o saldo nem alteram o equipamento.
- Orientação curta no primeiro jogo, recuo visual distinto por arma e postura de recarga. Os sons específicos e as variantes de alienígenas existentes são preservados.
- Tiros e faíscas usam pools pertencentes à cena, com 24/8 entradas preparadas e limites rígidos de 64/12. Entradas inativas ficam invisíveis, sem física e fora dos grupos de combate. Todas as propriedades são reinicializadas ao reutilizar; trocar/reiniciar a cena libera o pool inteiro.

Validação adicional: `tests/progression_smoke.gd` cobre migração do salvamento, compras inválidas/saldo/limites, falha de escrita com reversão, equipamento e dano/recarga reais, 2.500 ciclos de reutilização sem criar novos tiros/faíscas, teto de objetos, três ondas reais e recompensas. Isso verifica limites e redução de alocações; não representa uma medição de FPS em aparelho físico.
