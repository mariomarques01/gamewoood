# Recuperação da câmera — 0.11.1

Uma posição não finita (NaN/Infinity) do personagem podia contaminar a matriz da
câmera. A proteção anterior corrigia apenas `follow_position`: `Node3D.look_at`
preserva a escala derivada da matriz anterior, portanto uma base inválida
continuava inválida mesmo depois de o personagem voltar ao mapa. Em reprodução
controlada com Godot 4.6.3, a câmera permaneceu inválida por 120 atualizações após
a restauração da posição. Isso explica um caminho para a tela de fundo azul com
HUD visível e recuperação apenas ao reiniciar.

A câmera agora rejeita posições não finitas e reconstrói sua transformação rígida
com `Basis.looking_at`, sem reutilizar a base anterior. O enquadramento de vitória
também usa uma base limpa. O personagem recupera coordenadas inválidas antes da
física e da leitura dos controles; os limites do mapa verificam os três eixos.
Impactos com coordenadas inválidas são ignorados.

`tests/camera_recovery_smoke.gd` cobre base corrompida, alvo inválido, teleporte e
vitória. `tests/rendering_smoke.gd` verifica os pixels em 21 regiões após corromper
a câmera e também exercita a recuperação de altura NaN do personagem.
A fixture web acrescenta um 13º caso com corrupção e recuperação da câmera,
seguido das duas voltas de combate existentes pelo heliponto.

A injeção de coordenadas inválidas reproduz a falha de recuperação; ainda não
identifica qual evento no aparelho original gerou essas coordenadas. A hipótese
de proximidade dos prédios precisa de confirmação em aparelho físico. Os testes
em software e em navegador emulado não certificam todas as GPUs mobile.
