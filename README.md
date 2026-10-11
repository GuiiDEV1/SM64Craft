# SM64Craft

### Uma partida de Super Mario 64 Coop DX, vista e controlada pelo Minecraft.

<p align="center">
  <img src="docs/screenshots/sm64craft-coop.jpg" alt="Dois jogadores de Minecraft no gramado do castelo de Peach" width="49%">
  <img src="docs/screenshots/sm64craft-steve.jpg" alt="Steve encara a câmera no gramado do castelo" width="49%">
</p>

**[Baixe o JAR mais recente](https://github.com/GuiiDEV1/SM64Craft/releases/latest)** · [Relatar um problema](https://github.com/GuiiDEV1/SM64Craft/issues)

SM64Craft combina uma instância Fabric com o executável local do SM64 Coop DX. A imagem e o menu do SM64 aparecem dentro do Minecraft; Steve, os itens e as interações com blocos vêm da integração. O jogador fornece a ROM, e ela permanece no próprio computador.

## O caminho dos dados

```text
Teclado e mouse
      │
      ▼
Minecraft + Fabric ◄──── estado do jogador, blocos e colisão ────► SM64 Coop DX
      │                                                               │
      └──────── mundo Minecraft do host ◄──── e4mc ──────┐            │
                                                        amigos ◄── sala Coop DX
```

O Minecraft mantém Steve, inventário, vida e o mundo que os amigos visitam. O SM64 Coop DX executa menus, fases, inimigos e salas multiplayer. O mod conecta essas duas partes para que ações feitas em um lado apareçam no outro.

## Primeira execução

**Compatibilidade do instalador:** Windows 10/11 de 64 bits, Minecraft Java 26.3, Fabric Loader, Fabric API, Java 25 e internet. A instância Fabric e o Minecraft são pré-requisitos; o instalador do SM64Craft não os baixa.

1. Coloque o JAR da [última versão](https://github.com/GuiiDEV1/SM64Craft/releases/latest) em `mods` na instância Fabric e inicie o Minecraft.
2. No menu principal, clique em **Instalar dependências** e depois em **Abrir pasta sm64craft**.
3. Copie para essa pasta uma ROM USA sua (`.z64`, `.n64` ou `.v64`). Volte ao jogo e clique de novo em **Instalar dependências**.
4. O instalador confere a região, prepara uma cópia local da ROM, baixa o lançamento oficial do SM64 Coop DX, aplica o patch e instala o e4mc nessa instância.
5. Ao concluir, reinicie o Minecraft para carregar o e4mc. Abra o botão do mod no menu principal para navegar pelo menu do SM64 Coop DX dentro do Minecraft.

A ROM não vem no JAR, não é enviada pela instalação e não é alterada: o arquivo de trabalho normalizado é criado ao lado dela. O pacote público contém os arquivos de instalação e o patch, não uma ROM ou o executável completo do jogo. O caminho de lançamento usa um binário pronto, sem compilação local.

## Como montar uma sessão coop

1. Todos instalam o mesmo JAR e fornecem sua própria ROM USA.
2. O host abre um mundo Minecraft para LAN e inicia uma sala no menu do SM64 Coop DX.
3. Cada amigo entra na sala Coop DX pelo menu multiplayer do SM64.
4. A integração passa o endereço e4mc da sessão; o Minecraft dos convidados se conecta ao mundo do host.

Se a entrada automática precisar de ajuda, o endereço do host também pode ser usado no chat do Minecraft: `/join <endereço>`. `/leave` retorna o jogador à sessão local. Não é necessário manter um servidor Minecraft separado nem configurar portas no roteador.

### O que foi exercitado

Testes locais com vários clientes verificaram conexão e reconexão, inventário, blocos, mortes, estrelas, mudanças de fase e as passagens de DDD e WDW nos dois sentidos. Uma sala privada CoopNet também foi acessada com identidades de desenvolvimento. A validação entre computadores físicos com contas Microsoft distintas, percursos manuais de todos os cursos, chefes e campanha completa continua pendente. Os detalhes estão no [relatório de multiplayer](docs/MULTIPLAYER-VALIDATION.md).

## Comandos de movimento

Os controles normais do Minecraft continuam ativos. Os movimentos de Mario usam estes atalhos:

| Movimento | Entrada |
| --- | --- |
| Salto duplo / triplo | Espaço ao tocar o chão; corra para completar o triplo |
| Salto longo | Shift + Espaço correndo |
| Mortal para trás | Shift + Espaço parado |
| Wall kick | Espaço no ar contra uma parede |
| Ground pound | Segure Shift na aterrissagem |
| Conversar ou pegar | Botão direito |
| Guiar slide, canhão ou casco | WASD + mouse; Espaço para soltar |
| Menu de pausa do SM64 | P |
| Mudar perspectiva | F5 |
| Linha de diagnóstico | F7 |

## Seus arquivos

Tudo é gravado no diretório de jogo da instância ativa:

- `sm64craft/baserom.us.z64` — cópia verificada usada pelo jogo. O dump que você colocou permanece na pasta original.
- `sm64craft/saves/` — progresso do SM64.
- `sm64craft/install.log` — detalhes de uma instalação com erro.
- `mods/` — JAR do SM64Craft e o e4mc instalado pelo assistente.
- `saves/` — mundos normais do Minecraft.

Para desinstalar, feche o Minecraft e remova o JAR do SM64Craft de `mods`. O e4mc pode ser removido também, caso não seja usado por outro mod. Apagar `sm64craft/` remove o jogo nativo, os saves e todos os arquivos de ROM guardados lá; faça backup primeiro se quiser conservar algo.

## Licenças e créditos

O jogo executado é [SM64 Coop DX](https://github.com/coop-deluxe/sm64coopdx), da equipe Coop Deluxe. A camada que tornou possível apresentar um jogo dentro do Minecraft teve origem no [SkyCraft](https://github.com/chasmlol/SkyCraft), de chasm. Também são usados Fabric, Fabric API e e4mc.

O código do SM64Craft está sob MIT (`LICENSE`). As dependências mantêm seus próprios termos, listados em [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) e em `licenses/`. Este projeto de fãs não é afiliado à Nintendo, Mojang Studios ou Microsoft. Use suas próprias cópias dos jogos e não compartilhe ROMs.
