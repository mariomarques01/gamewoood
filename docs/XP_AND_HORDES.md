# XP, Fúria Tranco e hordas

A direção visual usa as referências fornecidas de Zombiewood como inspiração de
legibilidade, combate com hordas e manchas no cenário. Os modelos, geometria e
interface continuam sendo próprios do PROJECT DEADLIGHT.

## Progressão durante a partida

Cada alienígena eliminado concede **10 XP**, inclusive em explosões. A primeira
**Fúria Tranco** exige **100 XP** e ativa automaticamente por **10 segundos**:

- dano dos projéteis multiplicado por **3**;
- intervalo de disparo reduzido para **45%** do normal;
- velocidade de movimento multiplicada por **1,5**;
- munição ilimitada, com recargas interrompidas ao ativar;
- arma ampliada, projéteis dourados, aura e contagem regressiva no HUD.

A exigência aumenta em 40 XP por ativação, até o limite de 300 XP. XP ganho durante
a habilidade carrega a próxima ativação, até o limite atual. A pausa congela a
duração. A habilidade termina com a partida, e XP/nível recomeçam ao reiniciar.
O bônus anterior de cinco eliminações rápidas (Tranco Total, quatro segundos)
continua disponível e não substitui o aviso da habilidade maior.

## Inimigos e custo de renderização

Hordas de dois a quatro alienígenas surgem em intervalos de 3,2 a 2 segundos, com
limite de **24 inimigos simultâneos**. Os tipos são soldado, atirador, corredor
(mais rápido e frágil) e brutamontes (mais lento e resistente). Separação local
reduz a sobreposição. Os corpos agrupam peças de geometria/material iguais em
MultiMeshes, mantendo pés animados e materiais de dano independentes.

O sangue forma poças pequenas e 11 gotas espalhadas por até 1,8 metro ao redor
da eliminação. Cada conjunto é um mesh, dura até **30 segundos** e tem limite de
**32 conjuntos**, independentemente dos fragmentos de curta duração. O sangue
usa superfícies 3D compatíveis com WebGL 2, sem exigir decals do renderer Forward+.

## Interface e cenário

Barlow Condensed Bold/SemiBold são distribuídas localmente sob SIL OFL 1.1 em
`assets/fonts/OFL.txt`; não dependem de requisições externas. O HUD mostra XP,
limiar, duração e efeitos da Fúria, com contorno para legibilidade. O cenário
recebe calçadas modulares, meio-fio pintado, uma travessia entre calçadas com acessos rebaixados, bueiros, drenos, detalhes
nos alienígenas e filtragem com mipmaps no asfalto.

## Verificação

`tools/validate.sh --export` inclui `tests/evolution_smoke.gd`: morte real e XP
único, limiar da habilidade, dano, cadência, munição, movimento, pausa, expiração,
variantes e orçamento/duração de sangue. O teste de estresse existente exercita
24 inimigos. Os testes web existentes verificam controles desktop/mobile e PWA.
A aparência e o desempenho em aparelhos físicos ainda precisam de validação.
