# XP, Fúria Tranco e hordas

A direção visual usa as referências fornecidas de Zombiewood como inspiração de
legibilidade, combate com hordas e manchas no cenário. Os modelos, geometria e
interface continuam sendo próprios do PROJECT DEADLIGHT.

## Progressão durante a partida

Cada alienígena eliminado concede **10 XP**, inclusive em explosões. A primeira
**Fúria Tranco** exige **180 XP** e ativa automaticamente por **10 segundos**:

- dano dos projéteis multiplicado por **3**;
- intervalo de disparo reduzido para **45%** do normal;
- velocidade de movimento multiplicada por **1,5**;
- munição ilimitada, com recargas interrompidas ao ativar;
- arma ampliada, projéteis dourados, aura e contagem regressiva no HUD;
- faixa animada ao ativar, onda de energia, partículas e sinal sonoro.

A exigência aumenta em 80 XP por ativação, até o limite de 500 XP. Eliminações
durante a Fúria não carregam a próxima ativação. A pausa congela a
duração. A habilidade termina com a partida, e XP/nível recomeçam ao reiniciar.
Tranco Total exige dez eliminações rápidas e tem intervalo mínimo de 25 segundos
entre ativações, inclusive por itens. Itens de boost caem a cada 24 eliminações.
O aviso dura 1,2 segundo em uma faixa compacta no topo; a barra de XP exibe
a duração ativa, sem textos grandes repetidos sobre o combate.

## Inimigos e custo de renderização

Hordas de dois a quatro alienígenas surgem em intervalos de 3,2 a 2 segundos, com
limite de **24 inimigos simultâneos**. Os tipos são soldado, atirador, corredor
(mais rápido e frágil) e brutamontes (mais lento e resistente). Separação local
reduz a sobreposição. Os corpos agrupam peças de geometria/material iguais em
MultiMeshes, mantendo pés animados e materiais de dano independentes.

O sangue forma poças pequenas e 11 gotas espalhadas por até 1,8 metro ao redor
da eliminação. Cada conjunto é um mesh, dura até **30 segundos** e tem limite de
**32 conjuntos**, independentemente dos fragmentos de curta duração. O sangue
acompanha a altura visual do asfalto e do heliponto, para não ficar sob o piso, e
usa superfícies 3D compatíveis com WebGL 2, sem exigir decals do renderer Forward+.

## Interface e cenário

Lilita One (títulos cartoon) e Nunito (textos de apoio) são distribuídas
localmente sob SIL OFL 1.1 em `assets/fonts/LilitaOne-OFL.txt` e
`assets/fonts/Nunito-OFL.txt`; não dependem de requisições externas. O HUD mostra XP,
limiar, duração e efeitos da Fúria, com contorno para legibilidade. O cenário
recebe calçadas modulares, meio-fio pintado, uma travessia entre calçadas com acessos rebaixados, bueiros, drenos, detalhes
nos alienígenas e filtragem com mipmaps no asfalto.

## Verificação

`tools/validate.sh --export` inclui `tests/evolution_smoke.gd`: morte real e XP
único, limiar da habilidade, dano, cadência, munição, movimento, pausa, expiração,
variantes e orçamento/duração de sangue. O teste de estresse existente exercita
24 inimigos. Os testes web existentes verificam controles desktop/mobile e PWA.
A aparência e o desempenho em aparelhos físicos ainda precisam de validação.

As ruas usam asfalto escuro uniforme, sem a textura que criava listras. Áreas
livres são calçadas, sem terra exposta. As seis árvores recebem canteiros pequenos
de grama, com cercas baixas e tufos confinados à área cercada.
As calçadas continuam pavimentadas e o heliponto permanece asfaltado.
