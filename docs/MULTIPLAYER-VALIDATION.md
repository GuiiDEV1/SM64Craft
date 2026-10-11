# Validação do multiplayer — 0.1.9 e 0.1.10

Data: 10 de outubro de 2026. Os testes usam mundos próprios em
`dist/multiplayer-probe`, sem alterar os saves da instância MarioCraft-View.

## Ambiente e limites

Foram usados três clientes reais Minecraft 26.3/Fabric e três processos reais
SM64 Coop DX, com canais de memória separados, no mesmo PC. O SM64 conecta por
socket local; o Minecraft dos convidados recebe o endereço do anfitrião pelo
SM64 e conecta através do endereço público e4mc. As identidades são offline de
desenvolvimento: essa execução não verifica autenticação Microsoft ou CoopNet
entre PCs distintos.

As mudanças de fase foram acionadas por um mod Lua exclusivo do cenário de
teste. Blocos e dano foram acionados por um controlador exclusivo de clientes
de desenvolvimento. Isso verifica a integração real e os pacotes, mas não
substitui uma partida manual completa.

## Ampliação com identidades locais — 0.1.10

- CoopNet real: anfitrião criou uma sala privada; o convidado abriu Join > Private
  Lobbies no menu embutido, digitou a senha/código, encontrou a sala e entrou.
  Em seguida o Minecraft conectou automaticamente via e4mc; os dois clientes
  reportaram dois participantes. Esse teste usa senha de sala privada, não
  autenticação Microsoft ou convite por Discord.
- O controlador de desenvolvimento envia os mesmos eventos pela fila de menu
  usada pelo Minecraft. Para operar em segundo plano, somente o cenário de
  desenvolvimento com propriedade explícita pode simular foco e ponteiro.
- Missões diferentes antes compartilhavam o mesmo worldId da ponte, embora o
  Coop DX as mantenha separadas. Agora missões 2..6 de fases principais usam
  regiões distintas. Primeira missão, castelo e fases secretas mantêm os IDs
  anteriores; construções antigas continuam na primeira missão.
- O helper C de IDs passou pelas seis missões em 144 combinações de fase/área,
  sem colisões entre missões e dentro dos limites de coordenadas do Minecraft.
- O cenário ampliado carregou 117 destinos com `warp_to_level`, incluindo as
  90 missões principais. As duas áreas restantes foram exercitadas à parte
  pelas próprias passagens do jogo, como detalhado abaixo. Carregar uma arena
  não é considerado derrotar seu chefe ou concluir a campanha.
- A segunda entrada pela sala privada passou com o executável final 0.1.10:
  dois participantes, conexão automática ao novo endereço e4mc e sete diamantes
  preservados no inventário do convidado.
- Instalador rápido: 6,12 segundos sem contar download, 108,02 MiB instalados,
  save preservado e rejeição de fontes corrompidas e delta truncado.
- Passagens de DDD área 1 ↔ 2 e WDW área 1 ↔ 2: os pisos de warp do jogo
  acionaram as trocas reais nos dois clientes em ambas as direções. Os
  jogadores mantiveram uma estrela, vida e o mesmo grupo multiplayer nas duas
  áreas; o retorno carregou a colisão correta do Minecraft.
- Na execução de retorno, o cliente convidado ficou parado debaixo d'água no
  cenário automatizado: a vida do Mario nativo caiu de 2176 para 908 em DDD e
  continuou caindo em WDW, sem chegar a zero. As amostras de vida do jogador
  Minecraft permaneceram cheias. Isso não substitui uma verificação manual de
  movimento e sobrevivência nessas áreas.
- Progressão de uma estrela: sem estrelas, a porta de uma estrela reproduziu o
  diálogo de bloqueio. Depois de posicionar o anfitrião sobre uma estrela real
  existente em Bob-omb Battlefield, a coleta normal sincronizou uma estrela
  para anfitrião e convidado. Ambos iniciaram a animação nativa de abertura da
  porta; a bandeira de liberação apareceu durante a sessão.
- Reabertura dos processos confirmou que a estrela continuou salva e disponível
  como requisito da porta. A bandeira separada de animação (`0x800`) não foi
  gravada no arquivo de save ao sair da sala. Como o requisito é a contagem
  persistente de estrelas, a porta continua atendendo a condição de uma estrela;
  não afirmo que essa bandeira de animação persista.
- Os cenários são automatizados e posicionam os jogadores junto aos gatilhos ou
  sobre a estrela existente; eles exercitam as rotinas nativas reais, mas não
  simulam uma partida percorrida manualmente.

## Resultados comprovados

| Caso | Evidência |
|---|---|
| Entrada automática | Convidado recebe o domínio via sessão SM64; conecta sem `/join` manual. |
| Três jogadores | Os três clientes e o servidor reportam três participantes no mesmo mundo. |
| Blocos compartilhados | Bloco de diamante colocado no servidor aparece no convidado; sua remoção também aparece. |
| Inventário individual | Sete diamantes entregues ao convidado permanecem após fechar e reconectar os clientes. |
| Morte do convidado | Dano letal comum gera perda de vida no SM64, restaura os corações e conserva os sete diamantes, sem tela de respawn. |
| Progresso de estrela | Estrela gerada no cenário foi coletada; ambos os SM64 passam de zero para uma estrela. |
| Fases independentes | Anfitrião e convidados ocupam Bob-omb Battlefield, Whomp's Fortress e castelo em momentos distintos, sem arrastar o grupo. |
| Piso após retorno | Na execução final, 76 amostras do anfitrião e 63/64 dos convidados mantêm Y=1,71 no castelo, sem queda pela geometria anterior. |
| Teletransporte | Sequências de confirmação na memória correspondem ao pedido nativo de cada jogador. |
| Reinício | Clientes voltam a conectar quando o domínio e4mc muda; reinício do nativo também atualiza lobby e skin. |

## Erros encontrados e corrigidos

- O lobby Java conservava a sequência e a skin do processo nativo anterior.
  Agora reinicia esses dados quando muda a geração do link.
- O convidado passava por uma segunda checagem de colisão no servidor, diferente
  do anfitrião. Jogadores integrados passam a usar a mesma política; a física
  original é restaurada ao desconectar.
- A ponte podia exportar a geometria de uma fase anterior durante uma troca.
  Agora espera uma identificação e uma geração de superfícies estáveis e reenvia
  a colisão ao recarregar uma área, mesmo com o mesmo número de fase.
- Dados de região enviados por convidados podiam substituir a geometria local.
  Regiões recebidas do nativo local têm prioridade, com regressões automatizadas.
- A espera de teletransporte podia usar voxels e regiões em cache antes de chegar
  a malha nova. Agora exige o mesmo epoch de colisão e piso exato, preservando
  saídas intencionais no ar e o timeout depois de receber os dados corretos.
- A colisão de convidados ficava em cache entre servidores. Esse cache agora
  é limpo ao encerrar o servidor.
- Os canais padrão colidiam em testes com várias instâncias no mesmo PC.
  Canais alternativos de gameplay e vídeo podem ser passados pelo lançador.

## Testes automatizados

- JUnit: 43 testes aprovados de teletransporte, montagem de mensagens, prioridade de regiões, prontidão
  da geometria, roteamento de entrada e colisão triangular.
- C extraído da implementação: 31 asserções de geometria, transições, quadros e
  mastros; 13 asserções de entrada e seleção de movimentos do Mario.
- Layout: nove offsets Java/C correspondem; formato McState preservado.
- ROM: normalização dos formatos e recusa de sobrescrever uma ROM inválida.
- Patches reproduzem as fontes; delta nativo verificado contra o executável final.

## Validação que ainda falta

Autenticação com contas Microsoft distintas e CoopNet entre PCs distintos ainda
requerem dois computadores e contas válidas. Uma estrela e as duas passagens foram
testadas com cenários que posicionam os jogadores nos gatilhos; percorrer cada
trecho manualmente, concluir a campanha e derrotar todos os chefes continuam
pendentes. Também faltam todos os movimentos especiais e veículos em coop, perda
prolongada de rede e encerramento abrupto do anfitrião.

## Reproduzir em desenvolvimento

1. Compilar o nativo com os patches e executar `exportMultiplayerLaunch` no Gradle.
2. Executar `tools/start-multiplayer-probe.ps1 -Role Host`, depois `Guest` e `Guest2`.
3. Observar `probe/state.json`, `probe/server.json` e os logs de cada cliente.
4. Os comandos de diagnóstico só são registrados com Fabric em desenvolvimento
   e `-Dmariocraft.probe=<pasta>`; não são ativados na instância normal.
5. Fechar os clientes pelo comando `quit` e os nativos pelo helper `--close`.

O cenário Lua não é copiado para a instalação do usuário nem para o pacote público.

No controlador de diagnóstico, um comando `quit` antigo foi reaplicado ao abrir
outro cliente, causando encerramento durante a carga de shaders e um crash nativo
Java/ShaderC. O lançador agora descarta comandos do processo anterior. A repetição
entrou no servidor, recuperou os sete diamantes e confirmou o teletransporte.
Essa correção é do cenário de teste; não atribuímos o crash ao protocolo multiplayer.
