# Correções locais e validação

As alterações de jogo ficam em `patches/sm64coopdx.patch` e `patches/skycraft.patch`.
As pastas `sm64coopdx/` e `SkyCraft/` são geradas e ignoradas pelo Git. Alterar só
essas pastas não preserva uma correção numa instalação nova.

## Comportamento corrigido

- Saves: cada slot A/B/C/D escolhe seu próprio mundo Minecraft. O Erase explícito
  grava uma nova identidade em `mariocraft-slots.dat` antes de apagar
  o save SM64. Ao voltar ao slot, Minecraft cria um mundo novo, incluindo chunks,
  inventário, entidades e dados de escavação. Mundos anteriores ficam preservados.
  O servidor local é fechado normalmente antes da troca; os mundos de anfitriões
  remotos não são apagados pelo convidado. O cache nativo de escavação é limpo
  quando Minecraft envia novamente o mundo.
- Migração: o primeiro slot selecionado que ainda não recebeu Erase nesta versão
  herda o antigo mundo compartilhado `MarioCraft`. Se esse primeiro slot já foi
  apagado, o mundo legado é preservado separado e o slot começa limpo. Um marcador
  em `config/mariocraft-slot-migration.txt` impede importar o legado outra vez.
  Para limpar o progresso antigo já importado, usar Erase novamente. O botão
  Copy do SM64 ainda copia apenas seu progresso SM64, não clona o mundo Minecraft;
  apagar arquivos de save manualmente também não substitui o Erase integrado.
  Builds nativo e Java (`assemble`) aprovados; esta revisão não teve teste de jogo.
- Revisão do Erase: a chamada foi movida do seletor clássico para a função comum
  `save_file_erase`, cobrindo também o menu DJUI do Coop Deluxe e chamadas Lua.
  O menu DJUI não passava pelo seletor clássico e por isso não mudava a identidade
  do mundo. O mundo ativo antigo foi arquivado em
  `mariocraft-backups/cache-reset-20261009-183919/MarioCraft-A-0`; a próxima entrada
  criará um mundo limpo. O inventário inicial continua recebendo o kit padrão do mod.
- A abertura dos mundos por slot reconhece seus nomes no tratamento da confirmação
  de worldgen experimental. Antes disso, o Minecraft oculto ficava aguardando em
  `BackupConfirmScreen` e SM64 continuava com Mario. A regra cobre o mundo legado
  e os nomes exatos `MarioCraft-[A-D]-<geração hexadecimal>`.

- Na saída de fase, morte e outras animações, SM64 mantém o controle da posição.
  Steve acompanha essa posição. A entrada em quadros fica bloqueada durante a
  saída e até o jogador permanecer 15 frames fora do gatilho.
- Ao soltar uma árvore, mastro, carona ou animação, a integração pede a posição
  final ao Minecraft e espera a confirmação antes de aplicar a velocidade. A
  posição antiga deixa de recolocar Steve no ponto de onde acabou de sair.
- Espaço solta árvores/mastros também durante a animação de agarrar; Shift solta
  sem salto. O mesmo mastro não pode agarrar novamente por 30 frames de jogo.
- Um movimento rápido que sai de uma borda deixa de herdar o estado "no chão"
  para o resto do trajeto. Isso corrige a atração para pisos mais baixos durante
  impulsos como os da spear, mantendo pousos, paredes, tetos e rampas.
- Revisão da spear: o estado "no chão" só ativa aderência quando os pés ainda
  tocam uma superfície. Impulsos horizontais acima de 0,45 bloco por tick não
  aderem a rampas descendentes; a decisão usa o impulso inteiro, antes de
  subdividir o trajeto. A caminhada mantém a aderência e a colisão continua
  bloqueando paredes, tetos e o chão. Dois novos testes falharam antes dessa
  revisão e passaram depois; o build e os 34 testes Java passaram. A confirmação
  desses casos no jogo continua necessária.
- No coop, teletransportes de convidados passam pelo servidor Minecraft e têm
  confirmação vinculada ao pedido. A volta do servidor não depende de uma mudança
  grande de posição enviada como se fosse uma caminhada normal.
- Reconexões reenviam a colisão da fase. Mensagens partidas têm limites de tamanho,
  ordem e número de partes; dados inválidos são descartados antes de entrar no cache.
  Desconexões removem montagens incompletas e inimigos temporários do convidado.
- O lobby continua tentando conectar com intervalos crescentes, até dois minutos,
  e abandona links de anfitrião sem atualização. A deduplicação de inimigos considera
  outros convidados, além do anfitrião.

## Como validar

Compilar SM64 com `make` dentro de `sm64coopdx/`. Compilar e executar os testes
Java com `gradlew.bat build` dentro de `SkyCraft/fabric/`, usando o JDK 25.
Executar `python tools/test-motion-policy.py` com o GCC no PATH verifica as funções
reais de proteção de saída/quadros/mastros em isolamento.
Os testes cobrem colisão, impulsos sobre bordas, limites de teletransporte e
mensagens de colisão partidas/interrompidas. Eles não substituem partidas reais.

`tools/update-patches.py PROJECT ARCHIVE --add PATH...` salva alterações dos fontes
nos patches a partir dos arquivos originais dos releases fixados pelo instalador.
`tools/validate-patches.py PROJECT ARCHIVE` aplica o patch em uma pasta temporária
e compara os fontes resultantes. A ROM e os saves não participam dessa verificação.

Validação registrada anteriormente para as correções de gameplay acima: os builds
e as asserções nativas passaram; os patches reproduziram as fontes dos releases
originais. No cenário de impulso sobre uma borda, a lógica anterior puxava o
jogador 0,4 bloco para baixo; a corrigida preservou a altura. Esses resultados
precedem a implementação Minecraft View abaixo e não validam sua captura nativa.

## Validação em jogo ainda necessária

1. Coletar uma estrela, morrer e usar Exit Course: ver a saída completa, ficar no
   castelo e entrar novamente no quadro de propósito.
2. Agarrar a árvore, subir até o topo, sair com um Espaço e soltar com Shift;
   verificar também Hoot, canhão e slides.
3. Usar a spear no chão, sobre uma borda e já no ar; repetir perto de rampas,
   paredes, plataformas móveis e blocos colocados.
4. Jogar com dois e três jogadores com esta mesma versão instalada. Trocar de
   fase juntos e separadamente, combater inimigos e chefes, construir/minerar,
   morrer, desconectar e entrar novamente. Repetir com latência de rede real.

## Minecraft View (ponte de vídeo local)

O modo Minecraft View reutiliza o jogo externo e o link antigo MarioCraft. O
sm64coopdx continua responsável por executar e desenhar SM64; ele publica quadros
RGBA por um segundo mapeamento local. O cliente Fabric mostra esse quadro na janela
visível do Minecraft. Teclado e mouse pertencem ao Minecraft enquanto essa janela
está focada; ao alternar para SM64, o caminho de entrada antigo volta a funcionar.

O modo é opt-in e usa o perfil/saves `MarioCraft-View`. O perfil e o launcher
clássicos continuam separados. A ROM permanece local e nunca entra no JAR. Para
iniciar, use `Play Minecraft View.bat`; ele prepara o perfil, inicia o SM64 e abre
o Minecraft pelo Prism. A ponte não transforma a ROM nem as fases em blocos nativos
do Minecraft.

### Validação do Minecraft View

- O build nativo do SM64 passou com o MSYS2 local; os capturadores SDL/OpenGL e
  DirectX 11 foram compilados e o executável resultante abriu a ROM local.
- `gradlew.bat build` no `SkyCraft/fabric/` passou com Java 25 e os 34 testes Java.
  O JAR com `FrameLink` e `MinecraftSm64View` foi instalado no perfil Prism
  separado `MarioCraft-View`.
- Um mundo de teste isolado abriu a tela do MarioCraft dentro da janela Minecraft.
  A primeira execução mostrou só um pixel azul: a chamada `GuiGraphicsExtractor.blit`
  usava coordenadas de destino e UV na ordem errada. Corrigida a chamada, o quadro
  renderizou corretamente.
- Em 2026-10-09, o primeiro teste de Host local reproduziu sufocamento do jogador,
  queda do link e quadro preto. O servidor integrado recebia os movimentos de transporte
  do SM64 como movimento normal e aplicava colisão/sufocamento da sua dimensão vazia.
- A ponte agora sincroniza a pose carregada no servidor integrado e nos servidores dos
  convidados, suprime os pacotes de movimento vanilla durante esse transporte e deixa
  o host do servidor integrado sem colisão autoritativa enquanto o link SM64 está ativo.
  O cliente continua resolvendo as colisões reais do SM64.
- Depois da correção, o teste no perfil separado entrou no mundo e iniciou Host local.
  Steve sobreviveu ao teleporte por mais de 40 segundos; enviei um comando de movimento
  por 1 segundo, o quadro seguiu visível e o link permaneceu ativo. Não houve
  `moved wrongly` nem sufocamento no log.
  Minecraft e SM64 fecharam normalmente pelo launcher.
- `gradlew.bat build` passou no Java 25 com os 34 testes existentes. `tools/validate-patches.py`
  reproduziu os 58 arquivos do SkyCraft fixado; `git diff --check` também passou.
- Pelo launcher, o fechamento normal do SM64 encerrou o Minecraft e o fechamento
  normal do Minecraft encerrou o SM64. O teste usou um caminho de save SM64
  temporário; o perfil clássico, a ROM e os mundos habituais não foram alterados.
- O teste de transporte foi local, no servidor integrado; uma partida com clientes
  em PCs diferentes ainda precisa de validação dedicada. O perfil clássico, a ROM e
  os saves habituais não foram usados.
- O reteste de 2026-10-09 encontrou uma regressão no stream: o contador de quadros
  parava em 6 enquanto o cliente Minecraft seguia ativo. A captura DirectX reutilizava
  uma única textura de leitura mesmo quando `Map(DO_NOT_WAIT)` ainda reportava a cópia
  pendente. A captura agora alterna entre três texturas, lê cópias prontas sem bloquear
  o render e limita o envio a 30 quadros por segundo. No jogo aberto, o contador chegou
  a 1.321 e avançou 128 quadros em seis segundos (21,3 fps observados).
- A captura também deixava o canal alfa indefinido em partes do buffer. O Minecraft
  mostrava essas áreas como um retângulo preto; os quadros publicados agora são opacos.
  A leitura do buffer confirmou zero pixels com alfa diferente de 255, e a imagem no
  Minecraft ficou sem o retângulo.
- A distância de simulação 4 era inválida nesta versão do Minecraft e voltava para 12.
  O View agora usa 6; o log confirmou o valor sem o aviso de opção inválida. O mundo
  gerenciado carregou 10 seções, e não houve registro de sufocamento no reteste.
- Build nativo do SM64 e `gradlew.bat build` passaram; os 34 testes Java passaram e o
  JAR corrigido foi instalado no perfil separado `MarioCraft-View`. O teste visível
  continuou aberto após a verificação. A medição de 21,3 fps foi curta e não garante
  esse desempenho em toda fase ou computador.
- `tools/validate-patches.py` confirmou que os dois patches atualizados reproduzem
  as 45 fontes do SM64 Coop DX e as 59 fontes do SkyCraft a partir dos releases fixados.
- O segundo reteste encontrou uma alocação por quadro em `FrameLink.poll`: o cliente
  copiava e criava um `byte[]` de até 3,5 MiB a cada render, mesmo se o contador do SM64
  não tivesse mudado. Agora ele só copia quadros novos para um buffer reutilizado.
  Depois de reiniciar com o JAR atualizado, uma amostra de 45 segundos avançou 960
  quadros (21,3 fps); a memória ficou entre 2.055 e 2.062 MiB e a janela permaneceu
  responsiva. O uso de memória ainda parte alto durante o carregamento do Minecraft.
- Para o modo Minecraft View, a resolução do SM64 fica em 960x540, o limite do
  Minecraft em 60 fps e a distância de renderização em 4; a distância de simulação
  válida permanece em 6. O LevelRenderer do Minecraft continua suprimido enquanto
  SM64 fornece a imagem, preservando a passagem que desenha mão e item.
- O olhar do mouse foi retestado no mundo: um movimento relativo alterou a câmera
  do SM64. A mão e o item apareceram em jogo normal. Durante o diálogo introdutório,
  o HUD e a mão do Minecraft sumiram, enquanto o texto do SM64 continuou; ao avançar
  e fechar o diálogo com Espaço, o HUD e o item reapareceram no quadro seguinte.
- O sinal de esconder HUD usa um bit opcional novo no estado compartilhado e fica
  ativo em cutscenes, diálogos do SM64 e seleção de estrela. `HudMixin` cancela a
  extração do HUD apenas enquanto esse bit está ligado e marca o estado de renderização
  como oculto para a mão; ao sair, a extração vanilla volta a respeitar a opção F1.
- Build nativo do SM64 e `gradlew.bat build` passaram após essas mudanças; os 34
  testes Java passaram. O JAR atualizado foi instalado no perfil isolado
  `MarioCraft-View`, e o teste manual carregou o mundo, avançou o diálogo, restaurou
  a interface e confirmou que as duas janelas permaneceram responsivas.
