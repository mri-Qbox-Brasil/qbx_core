# qbx_core — Manual

Framework base do servidor: jogadores, personagens, jobs e gangues, dinheiro, metadata, permissões, buckets, fila de entrada, persistência de veículos e a ponte de compatibilidade com o QBCore.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Convars](#convars)
5. [Configuração](#configuração)
6. [Dados compartilhados](#dados-compartilhados)
7. [Comandos](#comandos)
8. [Personagens](#personagens)
9. [Fila de entrada](#fila-de-entrada)
10. [Persistência de veículos](#persistência-de-veículos)
11. [Ponte QBCore](#ponte-qbcore)
12. [Integrações](#integrações)
13. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
14. [Localização](#localização)
15. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `oxmysql` | Sim | Persistência de jogadores, bans e grupos |
| `ox_lib` | Sim | Versão 3.20.0 ou superior. O recurso derruba o servidor na inicialização se a versão for menor |
| `ox_inventory` | Sim | Versão 2.42.1 ou superior, com `inventory:framework` = `qbx` |
| OneSync Infinity | Sim | Obrigatório; sem ele o `qbx_core` executa `quit immediately` |
| Servidor FiveM | Sim | Build `10731` ou superior (`dependencies` do `fxmanifest.lua`) |
| `illenium-appearance` | Não | Aparência do ped na tela de personagens (chamada dentro de `pcall`) |
| `mri_Qspawn` / `qbx_spawn` / `qbx_apartments` | Não | Escolha do ponto de spawn após entrar com o personagem |
| `mri_Qcarkeys` | Não | Usado por `giveVehicleKeys` (server) e `hasKeys` (client) nesta configuração |
| `qbx_management` | Não | Contas de sociedade (`getSocietyAccount`, `removeSocietyMoney`) para pagamento via sociedade |
| `qbx_idcard` | Não | Necessário porque os itens iniciais `id_card` e `driver_license` pedem metadata dele |

---

## Instalação

1. Copie a pasta `qbx_core` para `resources/`.
2. Importe o SQL:
   ```sql
   -- qbx_core.sql cria as tabelas players, bans e player_groups
   SOURCE qbx_core.sql;
   ```
3. Adicione ao `server.cfg`, antes de qualquer recurso que dependa do framework:
   ```
   setr inventory:framework "qbx"
   set onesync on

   ensure oxmysql
   ensure ox_lib
   ensure ox_inventory
   ensure qbx_core
   ```
4. Defina os grupos de ACE (veja abaixo). Sem eles nenhum comando administrativo funciona.
5. **Conflitos** — o `qbx_core` declara `provide 'qb-core'`. Não rode o `qb-core` original junto: os dois respondem por `exports['qb-core']`.

Checagens feitas na inicialização, todas fatais: versão do `ox_lib`, versão do `ox_inventory`, `inventory:framework` igual a `qbx` e OneSync Infinity ativo.

---

## Permissões (ACE)

Os grupos padrão são `god`, `admin` e `mod` (lista em `config.server.permissions`). Declare-os no `server.cfg`:

```
add_ace group.god command allow
add_principal group.god group.admin
add_principal group.admin group.mod

add_ace group.admin qbadmin.join allow
add_principal identifier.fivem:1 group.admin
```

| ACE | Efeito |
|---|---|
| `group.admin` | Todos os comandos administrativos (`/tp`, `/car`, `/setjob`, `/givemoney`, `/openserver`, …) |
| `admin` | Whitelist de entrada quando `config.server.whitelist` está ligado (`whitelistPermission`) e prioridade na fila (`Admin Queue`) |
| `qbadmin.join` | Permite entrar mesmo com o servidor fechado (`config.server.closed`) |

Além da ACE, os comandos administrativos exigem **opt-in**: enquanto `config.server.requireOptIn` for `true`, o admin precisa rodar `/optin` na sessão antes que os comandos passem.

---

## Convars

Todas opcionais; os valores abaixo são os padrões do código.

| Convar | Padrão | Efeito |
|---|---|---|
| `qbx:enablebridge` | `true` | Carrega a ponte de compatibilidade QBCore. `false` desliga |
| `qbx:allowmethodoverrides` | `true` | Permite que recursos sobrescrevam funções da ponte QBCore |
| `qbx:disableoverridewarning` | `false` | Silencia o aviso emitido quando uma função da ponte é sobrescrita |
| `qbx:enablequeue` | `true` | Liga a fila de entrada |
| `qbx:enableVehiclePersistence` | `false` | Liga a persistência de veículos |
| `qbx:vehiclePersistenceType` | `semi` | `semi` salva posição e propriedades ao sair do veículo; `full` salva continuamente |
| `qbx:bucketlockdownmode` | `inactive` | Modo de lockdown do bucket 0: `strict`, `relaxed` ou `inactive` |
| `qbx:max_jobs_per_player` | `1` | Máximo de jobs simultâneos por jogador |
| `qbx:max_gangs_per_player` | `1` | Máximo de gangues simultâneas por jogador |
| `qbx:setjob_replaces` | `true` | `SetJob` substitui o job atual em vez de adicionar |
| `qbx:setgang_replaces` | `true` | `SetGang` substitui a gangue atual em vez de adicionar |
| `qbx:cleanPlayerGroups` | `false` | Remove da tabela `player_groups` grupos que não existem mais nos arquivos compartilhados |
| `qbx:motd` | vazio | Mensagem do dia exibida ao jogador ao entrar |
| `qbx:acknowledge` | `false` | Confirma a leitura das mensagens de serviço do projeto Qbox |
| `qbx:serviceMessagesUrl` | URL do repo Qbox | Origem das mensagens de serviço |
| `qbx:discordlink` | `discord.gg/qbox` | Link do Discord usado pela ponte e pelos utilitários |

---

## Configuração

### `config/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `serverName` | string | Sim | Nome do servidor exibido na fila e em outros textos |
| `defaultSpawn` | vec4 | Sim | Coordenadas de spawn padrão |
| `notifyPosition` | string | Sim | Posição das notificações (`center-left`, `top`, `top-right`, …) |
| `starterItems` | array | Sim | Itens dados ao criar o personagem. Cada item: `name`, `amount` e um `metadata(source)` opcional |

### `config/client.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `statusIntervalSeconds` | número | Sim | Intervalo de checagem de fome/sede para tirar vida quando chega a zero |
| `loadingModelsTimeout` | ms | Sim | Tempo máximo de espera do `ox_lib` ao carregar modelos |
| `pauseMapText` | string | Sim | Texto acima do mapa de pausa (ESC). Vazio mostra "FiveM" |
| `characters.imageURL` | string | Sim | Imagem exibida na tela de personagens |
| `characters.iconAnimation` | string | Sim | Animação do ícone da tela de personagens |
| `characters.useExternalCharacters` | bool | Sim | `true` desliga a tela de personagens interna e delega a outro recurso |
| `characters.enableDeleteButton` | bool | Sim | Permite o jogador apagar o próprio personagem |
| `characters.startingApartment` | bool | Sim | Se `true`, exige escolha de apartamento no primeiro spawn (depende do `qbx_apartments`/`qbx_spawn`) |
| `characters.dateFormat` | string | Sim | Formato da data de nascimento |
| `characters.dateMin` / `dateMax` | string | Sim | Faixa aceita de data de nascimento, no mesmo formato de `dateFormat` |
| `characters.limitNationalities` | bool | Sim | Se `true`, a nacionalidade tem de sair da lista `nationalities` |
| `characters.nationalities` | array | Sim | Lista de nacionalidades aceitas |
| `characters.profanityWords` | tabela | Sim | Palavras bloqueadas nos nomes de personagem |
| `characters.locations` | array | Sim | Locais onde o ped de pré-visualização aparece (`pedCoords`, `camCoords` opcional). Escolhidos aleatoriamente |
| `discord.enabled` | bool | Sim | Liga o Rich Presence do Discord |
| `discord.appId` | string | Sim | Application ID do Discord |
| `discord.largeIcon` / `smallIcon` | tabela | Sim | `icon` e `text` dos ícones do Rich Presence |
| `discord.firstButton` / `secondButton` | tabela | Sim | `text` e `link` dos botões do Rich Presence |
| `hasKeys` | função | Sim | Usada apenas pela ponte QB. Nesta configuração consulta o `mri_Qcarkeys` |

Nota: `dateFormat`, `dateMin`, `dateMax` e `limitNationalities` aparecem duas vezes dentro de `characters`. Em Lua a última definição vence, então o formato efetivo é `YYYY-MM-DD` com faixa `1900-01-01` a `2006-12-31`.

### `config/server.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `updateInterval` | minutos | Sim | Frequência com que os dados do jogador são salvos |
| `money.moneyTypes` | tabela | Sim | Tipos de dinheiro e valor inicial (`cash`, `bank`, `crypto`). Um tipo adicionado nunca é removido do banco |
| `money.dontAllowMinus` | array | Sim | Tipos de dinheiro que não podem ficar negativos |
| `money.paycheckTimeout` | minutos | Sim | Intervalo do pagamento automático |
| `money.paycheckSociety` | bool | Sim | Se `true`, o salário sai da conta da sociedade do job (usa `getSocietyAccount`/`removeSocietyMoney`) |
| `player.hungerRate` | número | Sim | Velocidade com que a fome cai |
| `player.thirstRate` | número | Sim | Velocidade com que a sede cai |
| `player.bloodTypes` | array | Sim | Tipos sanguíneos sorteados na criação do personagem |
| `player.identifierTypes` | tabela | Sim | Geradores de identificadores únicos: `citizenid`, `AccountNumber`, `PhoneNumber`, `FingerId`, `WalletId`, `SerialNumber`. Cada um tem uma `valueFunction` |
| `characterDataTables` | array de pares | Sim | `{tabela, coluna}` apagados quando o personagem é deletado |
| `server.pvp` | bool | Sim | Liga o PvP (replicado em `GlobalState.PVPEnabled`) |
| `server.closed` | bool | Sim | Servidor fechado; só entra quem tem a ACE `qbadmin.join` |
| `server.closedReason` | string | Sim | Mensagem exibida a quem é barrado |
| `server.whitelist` | bool | Sim | Liga a whitelist de entrada |
| `server.whitelistPermission` | string | Sim | ACE exigida quando a whitelist está ligada |
| `server.discord` | string | Sim | Link de convite do Discord |
| `server.checkDuplicateLicense` | bool | Sim | Bloqueia entrada com a mesma license da Rockstar já conectada |
| `server.requireOptIn` | bool | Sim | Exige `/optin` antes dos comandos administrativos (marcado como deprecado em favor da ACE) |
| `server.permissions` | array | Sim | Grupos de permissão reconhecidos (`god`, `admin`, `mod`) |
| `characters.playersNumberOfCharacters` | tabela | Sim | Limite de personagens por license específica |
| `characters.defaultNumberOfCharacters` | número | Sim | Limite padrão de personagens |
| `logging.webhook` | tabela | Sim | Webhooks do Discord por canal: `default`, `joinleave`, `ooc`, `anticheat`, `playermoney` |
| `logging.role` | tabela | Sim | Cargos marcados em logs de alta prioridade |
| `persistence.lockState` | string | Sim | `lock` ou `unlock` — estado da tranca do veículo persistido ao spawnar |
| `giveVehicleKeys` | função | Sim | Entrega de chaves ao spawnar veículo. Nesta configuração chama `mri_Qcarkeys:GiveTempKeys` |
| `getSocietyAccount` | função | Sim | Saldo da sociedade. Nesta configuração usa `qbx_management:GetAccount` |
| `removeSocietyMoney` | função | Sim | Débito na sociedade. Nesta configuração usa `qbx_management:RemoveMoney` |
| `sendPaycheck` | função | Sim | Como o salário é entregue (padrão: `AddMoney('bank', ...)` + notificação) |

### `config/queue.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `timeoutSeconds` | segundos | Sim | Tempo para remover da fila quem desconectar enquanto espera |
| `joiningTimeoutSeconds` | segundos | Sim | Tempo para remover da fila quem desconectar durante o carregamento |
| `subQueues` | array | Sim | Sub-filas em ordem de prioridade. Cada uma tem `name`, `predicate(source)` opcional e `cardOptions`. A primeira sem `predicate` é a padrão |
| `waitingEmojis` | array | Sim | Emojis cosméticos exibidos junto ao tempo de espera |
| `useAdaptiveCard` | bool | Sim | Usa o adaptive card gerado por `generateCard` na tela de conexão |
| `generateCard` | função | Sim | Monta o adaptive card com posição, tamanho da fila e tempo decorrido |

---

## Dados compartilhados

| Arquivo | Conteúdo |
|---|---|
| `shared/jobs.lua` | Jobs. Chave em minúsculo. Campos: `label`, `type` (ex.: `leo`, `ems`), `defaultDuty`, `offDutyPay`, `grades[n] = { name, payment, isboss?, bankAuth? }` |
| `shared/gangs.lua` | Gangues. Mesma estrutura, sem `payment` obrigatório |
| `shared/items.lua` | Itens do QBCore (usados pela ponte). O `ox_inventory` continua sendo a fonte da verdade dos itens |
| `shared/vehicles.lua` | Catálogo de veículos: `name`, `brand`, `model`, `price`, `category`, `type`, `hash` |
| `shared/weapons.lua` | Armas do QBCore. Marcado como deprecado — só é necessário para a ponte QB |
| `shared/locations.lua` | Coordenadas nomeadas. Marcado como deprecado |
| `data/nationalities.lua` | Lista de nacionalidades |

Jobs e gangues também podem ser criados em runtime pelos exports `CreateJob`, `CreateJobs`, `CreateGangs`, `UpsertJobData`, `UpsertJobGrade` e afins — nesse caso ficam no banco, não nos arquivos.

---

## Comandos

Todos os comandos com `group.admin` também exigem `/optin` enquanto `config.server.requireOptIn` estiver ligado.

| Comando | Permissão | Descrição |
|---|---|---|
| `/id` | Qualquer jogador | Mostra seu ID de servidor |
| `/me [mensagem]` | Qualquer jogador | Emote de texto acima do personagem |
| `/ooc [mensagem]` | Qualquer jogador | Chat fora de personagem, alcance de 20 metros (admins em opt-in veem tudo e o log vai para o webhook `ooc`) |
| `/job` | Qualquer jogador | Mostra o job atual |
| `/gang` | Qualquer jogador | Mostra a gangue atual |
| `/optin` | `group.admin` | Alterna o opt-in de comandos administrativos |
| `/tp [id]` ou `/tp [x] [y] [z]` | `group.admin` | Teleporta até um jogador ou para coordenadas |
| `/tpm` | `group.admin` | Teleporta para o waypoint |
| `/togglepvp` | `group.admin` | Liga/desliga o PvP do servidor |
| `/car [modelo]` | `group.admin` | Spawna um veículo |
| `/dv` | `group.admin` | Apaga o veículo em que você está ou o mais próximo |
| `/givemoney [id] [tipo] [valor]` | `group.admin` | Adiciona dinheiro a um jogador |
| `/setmoney [id] [tipo] [valor]` | `group.admin` | Define o saldo de um jogador |
| `/setjob [id] [job] [grade]` | `group.admin` | Define o job primário |
| `/changejob [id] [job] [grade]` | `group.admin` | Troca o job do jogador |
| `/addjob [id] [job] [grade]` | `group.admin` | Adiciona um job ao jogador |
| `/removejob [id] [job]` | `group.admin` | Remove um job do jogador |
| `/setgang [id] [gang] [grade]` | `group.admin` | Define a gangue primária |
| `/addpermission [id] [permissão]` | `group.admin` | Adiciona um grupo de permissão ao jogador |
| `/removepermission [id] [permissão]` | `group.admin` | Remove um grupo de permissão |
| `/openserver` | `group.admin` | Reabre o servidor |
| `/closeserver [motivo]` | `group.admin` | Fecha o servidor (só entra quem tem `qbadmin.join`) |
| `/logout` | `group.admin` | Desloga o personagem e volta para a tela de seleção |
| `/deletechar [id]` | `group.admin` | Apaga o personagem de um jogador |

---

## Personagens

A tela de personagens é interna (`client/character.lua`) e usa menus do `ox_lib`.

- O limite de personagens vem de `config.characters.playersNumberOfCharacters` (por license) ou de `defaultNumberOfCharacters`.
- O ped de pré-visualização aparece em uma das `characters.locations`, sorteada a cada abertura, e recebe a aparência salva via `illenium-appearance` quando o recurso existe.
- Ao criar o personagem, os `starterItems` são entregues e os identificadores únicos (`citizenid`, telefone, conta, digital, carteira, número de série) são gerados pelas `identifierTypes`.
- Depois de entrar com o personagem, o spawn é resolvido nesta ordem: `mri_Qspawn` (`chooseSpawn`), senão `qbx_apartments` quando `startingApartment` está ligado, senão `qbx_spawn`, senão o `defaultSpawn`.
- Apagar o personagem remove as linhas listadas em `config.characterDataTables`.
- `useExternalCharacters = true` desliga toda essa tela e deixa o fluxo para outro recurso.

---

## Fila de entrada

Ligada por padrão (`qbx:enablequeue`). As sub-filas de `config/queue.lua` são avaliadas de cima para baixo pelo `predicate`; a primeira sem `predicate` é a fila padrão. Um jogador que não passe em nenhum `predicate` e não tenha fila padrão só entra se houver slot livre.

A configuração de fábrica tem duas: `Admin Queue` (para quem tem a ACE `admin`) e `Regular Queue`. A tela de conexão mostra o adaptive card com a posição, o total da fila e o tempo esperando.

---

## Persistência de veículos

Desligada por padrão. Para ligar:

```
setr qbx:enableVehiclePersistence "true"
setr qbx:vehiclePersistenceType "semi"   -- ou "full"
```

- `semi` — posição e propriedades são gravadas quando o jogador sai do veículo.
- `full` — gravação contínua enquanto o veículo existir.
- `config.persistence.lockState` define se o veículo volta trancado ou destrancado ao ser respawnado.
- Recursos podem ligar/desligar a persistência de um veículo específico com os exports `EnablePersistence` e `DisablePersistence`.

---

## Ponte QBCore

Com `qbx:enablebridge` (padrão `true`), o `qbx_core` expõe `exports['qb-core']:GetCoreObject()` e o objeto `QBCore` clássico (`QBCore.Functions.*`, `QBCore.Shared.*`, eventos `QBCore:*`). É o que permite rodar recursos escritos para QBCore sem alteração.

- `qbx:allowmethodoverrides` controla se um recurso pode sobrescrever funções da ponte; `qbx:disableoverridewarning` silencia o aviso quando isso acontece.
- `shared/weapons.lua` e `shared/items.lua` existem para alimentar `QBCore.Shared.Weapons` e `QBCore.Shared.Items` da ponte.
- Código novo deve usar os exports nativos do `qbx_core` — a ponte é apenas compatibilidade.

---

## Integrações

### ox_inventory

É o inventário oficial e obrigatório. A convar `inventory:framework` precisa estar em `qbx`, e `inventory:accounts` define quais tipos de dinheiro o inventário trata como conta.

### mri_Qcarkeys

Nesta configuração, `config.server.giveVehicleKeys` chama `exports.mri_Qcarkeys:GiveTempKeys(src, plate)` e `config.client.hasKeys` consulta `HaveTemporaryKey`/`HavePermanentKey`. Trocar de sistema de chaves é só editar essas duas funções (o código do `qbx_vehiclekeys` está comentado ao lado).

### qbx_management

Quando `money.paycheckSociety = true`, o salário é debitado da conta da sociedade do job usando `qbx_management:GetAccount` e `qbx_management:RemoveMoney`.

Atenção: `paycheckSociety` está `false` nesta configuração, e o `qbx_management` deste servidor **não expõe** `GetAccount` nem `RemoveMoney` (ele só faz o menu de chefe). Antes de ligar essa opção, aponte `getSocietyAccount` e `removeSocietyMoney` para um recurso de banco que tenha esses exports.

### mri_Qspawn / qbx_spawn / qbx_apartments

Definem para onde o jogador vai depois de escolher o personagem. O `qbx_core` testa o estado dos recursos nessa ordem e chama `exports['mri_Qspawn']:chooseSpawn()`, `apartments:client:setupSpawnUI` ou `qb-spawn:client:setupSpawns`.

### illenium-appearance

Aplica a aparência salva no ped de pré-visualização e no personagem carregado. As chamadas são feitas em `pcall`, então a ausência do recurso não quebra o fluxo.

### qbx_idcard

Os itens iniciais `id_card` e `driver_license` chamam `exports.qbx_idcard:GetMetaLicense`. Se o recurso não estiver rodando, a criação do personagem falha com assert — remova esses itens de `starterItems` se não usar o `qbx_idcard`.

---

## Entrypoints para outros recursos

### Módulos compartilhados

Outros recursos incluem os módulos do core diretamente no `fxmanifest.lua`:

```lua
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',        -- helpers qbx.* (string, math, table, array, spawnVehicle, getVehiclePlate…)
}
client_scripts {
    '@qbx_core/modules/playerdata.lua', -- mantém QBX.PlayerData sincronizado no cliente
}
```

No servidor, o logger é carregado por `require`:

```lua
local logger = require '@qbx_core.modules.logger'
```

### Exports de servidor — jogador

```lua
exports.qbx_core:GetPlayer(source)
exports.qbx_core:GetPlayerByCitizenId(citizenid)
exports.qbx_core:GetPlayerByPhone(number)
exports.qbx_core:GetPlayerByUserId(userId)
exports.qbx_core:GetOfflinePlayer(citizenid)
exports.qbx_core:GetQBPlayers()
exports.qbx_core:GetPlayersData()
exports.qbx_core:GetSource(identifier)
exports.qbx_core:GetUserId(source)

exports.qbx_core:CreatePlayer(playerData, isNew)
exports.qbx_core:Login(source, citizenid, newData)
exports.qbx_core:Logout(source)
exports.qbx_core:Save(source)
exports.qbx_core:SaveOffline(playerData)
exports.qbx_core:DeleteCharacter(citizenid)
exports.qbx_core:GenerateUniqueIdentifier('citizenid')
```

### Exports de servidor — dinheiro, dados e metadata

```lua
exports.qbx_core:AddMoney(source, 'cash', 100, 'motivo')
exports.qbx_core:RemoveMoney(source, 'bank', 100, 'motivo')
exports.qbx_core:SetMoney(source, 'cash', 100, 'motivo')
exports.qbx_core:GetMoney(source, 'cash')

exports.qbx_core:SetPlayerData(source, key, value)
exports.qbx_core:UpdatePlayerData(source)
exports.qbx_core:SetMetadata(source, 'armor', 100)
exports.qbx_core:GetMetadata(source, 'armor')
exports.qbx_core:SetCharInfo(source, 'phone', numero)
```

### Exports de servidor — jobs, gangues e grupos

```lua
exports.qbx_core:SetJob(source, 'police', 2)
exports.qbx_core:SetJobDuty(source, true)
exports.qbx_core:SetPlayerPrimaryJob(citizenid, 'police')
exports.qbx_core:AddPlayerToJob(citizenid, 'police', 2)
exports.qbx_core:RemovePlayerFromJob(citizenid, 'police')
exports.qbx_core:SetGang(source, 'ballas', 1)
exports.qbx_core:SetPlayerPrimaryGang(citizenid, 'ballas')
exports.qbx_core:AddPlayerToGang(citizenid, 'ballas', 1)
exports.qbx_core:RemovePlayerFromGang(citizenid, 'ballas')

exports.qbx_core:GetJobs()
exports.qbx_core:GetJob('police')
exports.qbx_core:GetGangs()
exports.qbx_core:GetGang('ballas')
exports.qbx_core:CreateJob('police', jobData)
exports.qbx_core:CreateJobs(jobsTable)
exports.qbx_core:RemoveJob('police')
exports.qbx_core:CreateGangs(gangsTable)
exports.qbx_core:RemoveGang('ballas')
exports.qbx_core:UpsertJobData('police', data)
exports.qbx_core:UpsertJobGrade('police', 2, gradeData)
exports.qbx_core:RemoveJobGrade('police', 2)
exports.qbx_core:UpsertGangData('ballas', data)
exports.qbx_core:UpsertGangGrade('ballas', 1, gradeData)
exports.qbx_core:RemoveGangGrade('ballas', 1)

exports.qbx_core:GetGroups(source)
exports.qbx_core:GetGroupMembers(name, type)
exports.qbx_core:HasGroup(source, filter)
exports.qbx_core:HasPrimaryGroup(source, filter)
exports.qbx_core:IsGradeBoss('police', 4)
exports.qbx_core:GetDutyCountJob('police')
exports.qbx_core:GetDutyCountType('leo')
```

### Exports de servidor — permissões e moderação

```lua
exports.qbx_core:AddPermission(source, 'admin')
exports.qbx_core:RemovePermission(source, 'admin')
exports.qbx_core:GetPermission(source)
exports.qbx_core:HasPermission(source, 'admin')
exports.qbx_core:IsOptin(source)
exports.qbx_core:ToggleOptin(source)
exports.qbx_core:IsPlayerBanned(source)
exports.qbx_core:IsWhitelisted(source)
exports.qbx_core:ExploitBan(source, motivo)
exports.qbx_core:Notify(source, 'mensagem', 'success')
```

### Exports de servidor — buckets, veículos e itens

```lua
exports.qbx_core:SetPlayerBucket(source, bucket)
exports.qbx_core:SetEntityBucket(entity, bucket)
exports.qbx_core:GetPlayersInBucket(bucket)
exports.qbx_core:GetEntitiesInBucket(bucket)
exports.qbx_core:GetBucketObjects()

exports.qbx_core:GetVehiclesByName()
exports.qbx_core:GetVehiclesByHash()
exports.qbx_core:GetVehiclesByCategory('super')
exports.qbx_core:GetVehicleClass(model)
exports.qbx_core:DeleteVehicle(vehicle)
exports.qbx_core:EnablePersistence(vehicle)
exports.qbx_core:DisablePersistence(vehicle)
exports.qbx_core:CreateSessionId(entity)

exports.qbx_core:CreateUseableItem(item, cb)
exports.qbx_core:CanUseItem(item)
exports.qbx_core:GetWeapons()
exports.qbx_core:GetLocations()
exports.qbx_core:GetCoreVersion()
```

### Exports de cliente

```lua
exports.qbx_core:GetPlayerData()
exports.qbx_core:GetJobs()
exports.qbx_core:GetJob('police')
exports.qbx_core:GetGangs()
exports.qbx_core:GetGang('ballas')
exports.qbx_core:GetGroups()
exports.qbx_core:HasGroup(filter)
exports.qbx_core:HasPrimaryGroup(filter)
exports.qbx_core:GetVehiclesByName()
exports.qbx_core:GetVehiclesByHash()
exports.qbx_core:GetVehiclesByCategory('super')
exports.qbx_core:GetWeapons()
exports.qbx_core:GetLocations()
exports.qbx_core:Notify('mensagem', 'success')
```

### Hooks

Permitem cancelar operações de dinheiro retornando `false`. Eventos disponíveis: `addMoney`, `removeMoney`, `setMoney`.

```lua
local hookId = exports.qbx_core:registerHook('addMoney', function(payload)
    -- payload traz source, moneyType, amount, reason
    if payload.amount > 1000000 then return false end -- cancela
end)

exports.qbx_core:removeHooks() -- remove todos os hooks do recurso que chamou
```

### Eventos (novos)

```lua
-- servidor
RegisterNetEvent('qbx_core:server:onJobUpdate', function(jobName, job) end)
RegisterNetEvent('qbx_core:server:onGangUpdate', function(gangName, gang) end)
RegisterNetEvent('qbx_core:server:onGroupUpdate', function(source, groups) end)
RegisterNetEvent('qbx_core:server:onSetMetaData', function(key, oldValue, newValue) end)
RegisterNetEvent('qbx_core:server:playerLoggedOut', function(source) end)

-- cliente
RegisterNetEvent('qbx_core:client:onJobUpdate', function(jobName, job) end)
RegisterNetEvent('qbx_core:client:onGangUpdate', function(gangName, gang) end)
RegisterNetEvent('qbx_core:client:onGroupUpdate', function(groups) end)
RegisterNetEvent('qbx_core:client:onSetMetaData', function(key, oldValue, newValue) end)
RegisterNetEvent('qbx_core:client:playerLoggedOut', function() end)
```

### Eventos (compatibilidade QBCore)

```lua
-- servidor
AddEventHandler('QBCore:Server:OnPlayerLoaded', function(player) end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source) end)
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job) end)
AddEventHandler('QBCore:Server:OnGangUpdate', function(source, gang) end)
AddEventHandler('QBCore:Server:OnMoneyChange', function(source, type, amount, operation, reason) end)
AddEventHandler('QBCore:Server:OnPermissionUpdate', function(source, permission) end)

-- cliente
AddEventHandler('QBCore:Client:OnPlayerLoaded', function() end)
AddEventHandler('QBCore:Client:OnPlayerUnload', function() end)
AddEventHandler('QBCore:Client:OnJobUpdate', function(job) end)
AddEventHandler('QBCore:Client:OnGangUpdate', function(gang) end)
AddEventHandler('QBCore:Client:OnMoneyChange', function(type, amount, isMinus) end)
AddEventHandler('QBCore:Client:SetDuty', function(onDuty) end)
AddEventHandler('QBCore:Player:SetPlayerData', function(playerData) end)
```

### Callbacks (`lib.callback`)

```lua
-- servidor -> cliente
lib.callback.await('qbx_core:client:getVehicleClasses', src)
lib.callback.await('qbx_core:client:getVehiclesInRadius', src, coords, radius)
lib.callback.await('qbx_core:client:setHealth', src, health)

-- cliente -> servidor (usados pela tela de personagens)
lib.callback.await('qbx_core:server:getCharacters')
lib.callback.await('qbx_core:server:createCharacter', false, data)
lib.callback.await('qbx_core:server:loadCharacter', false, citizenid)
lib.callback.await('qbx_core:server:deleteCharacter', false, citizenid)
lib.callback.await('qbx_core:server:getGroups')
lib.callback.await('qbx_core:server:getPreviewPedData', false, citizenid)
lib.callback.await('qbx_core:server:setCharBucket')
```

### GlobalState

```lua
GlobalState.PlayerCount   -- jogadores conectados
GlobalState.MaxPlayers    -- sv_maxclients
GlobalState.PVPEnabled    -- estado do PvP
```

---

## Localização

Strings via `ox_lib` locale. `locales/` traz mais de 35 idiomas, entre eles `en.json`, `pt-br.json`, `pt.json`, `es.json`, `fr.json`, `de.json`, `it.json`, `ru.json`, `pl.json`, `tr.json`, `ja.json`, `zh-tw.json`.

```
setr ox:locale "pt-br"
```

---

## Estrutura de arquivos

```
qbx_core/
├── client/
│   ├── main.lua                 — bootstrap do cliente, catálogos de veículos/armas/locais
│   ├── character.lua            — tela de personagens, ped de preview, spawn inicial
│   ├── events.lua               — eventos de player loaded/unload, MOTD, comandos de teleporte
│   ├── functions.lua            — helpers de cliente
│   ├── groups.lua               — cache de jobs/gangues e exports de grupo
│   ├── loops.lua                — loop de fome/sede
│   ├── discord.lua              — Rich Presence
│   └── vehicle-persistence.lua  — envio de posição/propriedades do veículo
├── server/
│   ├── main.lua                 — checagens de inicialização, buckets, catálogos, itens usáveis
│   ├── player.lua               — objeto Player: dinheiro, metadata, jobs, gangues, save/load
│   ├── character.lua            — criação, carregamento e exclusão de personagens
│   ├── groups.lua               — CRUD de jobs e gangues em runtime
│   ├── functions.lua            — permissões, notify, ban, whitelist, utilidades
│   ├── events.lua               — connecting/joining, fila, player dropped
│   ├── commands.lua             — todos os comandos do core
│   ├── loops.lua                — save periódico e paycheck
│   ├── queue.lua                — fila de entrada com adaptive card
│   ├── motd.lua                 — mensagens de serviço e MOTD
│   ├── vehicle-persistence.lua  — gravação de veículos persistentes
│   └── storage/
│       ├── main.lua             — acesso ao banco (bans, grupos)
│       └── players.lua          — leitura e escrita da tabela players
├── shared/
│   ├── main.lua                 — agrega Locations, Vehicles, Weapons e hashes
│   ├── jobs.lua                 — definição dos jobs
│   ├── gangs.lua                — definição das gangues
│   ├── items.lua                — itens para a ponte QBCore
│   ├── vehicles.lua             — catálogo de veículos
│   ├── weapons.lua              — armas para a ponte QBCore (deprecado)
│   ├── locations.lua            — coordenadas nomeadas (deprecado)
│   ├── functions.lua            — helpers compartilhados
│   └── locale.lua               — carregamento do locale
├── config/
│   ├── shared.lua               — nome do servidor, spawn padrão, itens iniciais
│   ├── client.lua               — personagens, Discord, status, hasKeys
│   ├── server.lua               — dinheiro, jogador, servidor, logging, persistência, sociedade
│   └── queue.lua                — sub-filas e adaptive card
├── modules/
│   ├── lib.lua                  — helpers qbx.* usados por todos os recursos da suite
│   ├── playerdata.lua           — QBX.PlayerData no cliente
│   ├── logger.lua               — envio de logs para webhook do Discord
│   ├── hooks.lua                — registerHook / removeHooks
│   └── utils.lua                — utilidades diversas
├── bridge/qb/                   — ponte de compatibilidade QBCore (client, server, shared)
├── data/
│   └── nationalities.lua        — lista de nacionalidades
├── locales/                     — 35+ idiomas
├── qbx_core.sql                 — tabelas players, bans e player_groups
├── types.lua                    — anotações de tipo para o LSP
└── fxmanifest.lua
```

Os arquivos `compare_items*.js`, `extract_*.js`, `extra_items.lua`, `missing_items.lua` e `compare_*.txt` na raiz são scripts avulsos de comparação de itens. Não são carregados pelo `fxmanifest.lua` e não fazem parte do runtime.
