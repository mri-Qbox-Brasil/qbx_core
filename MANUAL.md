# Manual do qbx_core

O framework principal para Qbox — base para servidores FiveM com suporte a multicharacter, múltiplos trabalhos/gangues, veículos persistentes e sistema de hooks.

## Funcionalidades Principais

### Sistema de Jogador
- **Multicharacter**: Criação e gerenciamento de múltiplos personagens por jogador
- **Multi-Trabalho/Gangue**: Suporte a múltiplos trabalhos e gangues simultâneos por jogador
- **Metadata**: Sistema completo de metadados (fome, sede, estresse, vida, colete, etc.)
- **Persistência**: Dados salvos automaticamente no banco de dados

### Sistema de Grupos
- **Trabalhos**: Definição de trabalhos com graus, salários e permissões
- **Gangues**: Sistema completo de gangues com hierarquia
- **Gerenciamento**: Adicionar/remover jogadores, alterar graus, definir grupo principal

### Veículos Persistentes
- Salva estado, propriedades, garagem e danos dos veículos
- Transferência de propriedade entre jogadores
- Rastreamento de estado (OUT, GARAGED, IMPOUNDED)

### Sistema de Hooks
- Hooks estilo Ox para estender funcionalidades
- Eventos disparados em ações importantes do core

### Anti-Cheat e Segurança
- Detecção de exploits integrada
- Desconexão automática de jogadores suspeitos

### Sistema de Fila
- Fila integrada para servidores cheios
- Whitelist configurável (servidor aberto/fechado)

## Configuração

### config/shared.lua
```lua
Config = {
    Spawn = vector4(-1037.37, -2737.66, 13.76, 206.12), -- Spawn padrão
    Player = {
        DefaultHealth = 200,
        DefaultArmor = 0,
        DefaultHunger = 100,
        DefaultThirst = 100,
    },
    Money = {
        types = {'cash', 'bank', 'crypto'}
    }
}
```

### config/server.lua
```lua
Config = {
    Logging = {
        webhook = '', -- URL do webhook Discord
        types = {'join', 'leave', 'death', 'commands'}
    },
    PvP = true, -- Ativar/desativar PvP global
    ClosedServer = false, -- Servidor fechado (whitelist)
}
```

### config/client.lua
```lua
Config = {
    MapText = 'Qbox Framework', -- Texto na tela de pause
    EnableDebug = false,
}
```

### Metadata do Jogador

| Campo | Tipo | Padrão | Descrição |
|-------|------|---------|-------------|
| `health` | number | 200 | Vida do jogador |
| `hunger` | number | 100 | Nível de fome (0-100) |
| `thirst` | number | 100 | Nível de sede (0-100) |
| `stress` | number | 0 | Nível de estresse (0-100) |
| `isdead` | boolean | false | Jogador está morto |
| `inlaststand` | boolean | false | Está em último alento |
| `armor` | number | 0 | Nível de armadura |
| `ishandcuffed` | boolean | false | Está algemado |
| `tracker` | boolean | false | Possui rastreador |
| `injail` | number | 0 | Tempo de prisão restante |
| `bloodtype` | string | Aleatório | Tipo sanguíneo |
| `dealerrep` | number | 0 | Reputação de traficante |
| `craftingrep` | number | 0 | Reputação de fabricação |
| `callsign` | string | 'NO CALLSIGN' | Indicativo do jogador |

## Comandos

### Administradores

| Comando | Permissão | Descrição |
|----------|-------------|-------------|
| `/tp [x] [y] [z]` | `group.admin` | Teletransportar para coordenadas |
| `/tp [id]` | `group.admin` | Teletransportar para jogador |
| `/tpm` | `group.admin` | Teletransportar para marcador |
| `/togglepvp` | `group.admin` | Alternar modo PvP |
| `/addpermission [id] [permission]` | `group.admin` | Adicionar permissão ACE |
| `/removepermission [id] [permission]` | `group.admin` | Remover permissão ACE |
| `/openserver` | `group.admin` | Abrir servidor (remover whitelist) |
| `/closeserver [reason?]` | `group.admin` | Fechar servidor (ativar whitelist) |
| `/car [model] [keepCurrent?]` | `group.admin` | Spawnar veículo |
| `/dv [radius?]` | `group.admin` | Deletar veículo(s) |
| `/givemoney [id] [type] [amount]` | `group.admin` | Dar dinheiro ao jogador |
| `/setmoney [id] [type] [amount]` | `group.admin` | Definir dinheiro do jogador |
| `/setjob [id] [job] [grade?]` | `group.admin` | Definir trabalho do jogador |
| `/changejob [id] [job]` | `group.admin` | Alterar trabalho principal |
| `/addjob [id] [job] [grade?]` | `group.admin` | Adicionar jogador a um trabalho |
| `/removejob [id] [job]` | `group.admin` | Remover jogador de um trabalho |
| `/setgang [id] [gang] [grade?]` | `group.admin` | Definir gangue do jogador |
| `/logout` | `group.admin` | Fazer logout do jogador |
| `/deletechar [id]` | `group.admin` | Deletar personagem |
| `/optin` | `group.admin` | Alternar opt-in de admin |

### Jogadores

| Comando | Descrição |
|----------|-------------|
| `/job` | Exibir informações do trabalho atual |
| `/gang` | Exibir informações da gangue atual |
| `/ooc [message]` | Chat fora de personagem |
| `/me [message]` | Exibir ação de roleplay |
| `/id` | Exibir seu ID do servidor |

## Exports (API)

### Server Exports

| Export | Parâmetros | Retorno | Descrição |
|--------|------------|--------|-------------|
| `GetPlayer` | `source` | `Player?` | Obter jogador online por source |
| `GetPlayerByCitizenId` | `citizenid` | `Player?` | Obter jogador online por citizen ID |
| `GetOfflinePlayer` | `citizenid` | `Player?` | Obter dados de jogador offline |
| `GetPlayers` | - | `table` | Obter todos os jogadores online |
| `Login` | `source, citizenid?, newData?` | `boolean` | Fazer login de um jogador |
| `Logout` | `source` | - | Fazer logout de um jogador |
| `CreatePlayer` | `playerData, Offline` | `Player` | Criar um novo jogador |
| `Save` | `source` | - | Salvar jogador online |
| `SaveOffline` | `playerData` | - | Salvar jogador offline |
| `SetJob` | `identifier, jobName, grade?` | `boolean, ErrorResult?` | Definir trabalho principal |
| `SetGang` | `identifier, gangName, grade?` | `boolean, ErrorResult?` | Definir gangue principal |
| `AddPlayerToJob` | `citizenid, jobName, grade?` | `boolean, ErrorResult?` | Adicionar jogador a um trabalho |
| `RemovePlayerFromJob` | `citizenid, jobName` | `boolean, ErrorResult?` | Remover jogador de um trabalho |
| `AddPlayerToGang` | `citizenid, gangName, grade?` | `boolean, ErrorResult?` | Adicionar jogador a uma gangue |
| `RemovePlayerFromGang` | `citizenid, gangName` | `boolean, ErrorResult?` | Remover jogador de uma gangue |
| `SetPlayerPrimaryJob` | `citizenid, jobName` | `boolean, ErrorResult?` | Definir trabalho principal |
| `SetPlayerPrimaryGang` | `citizenid, gangName` | `boolean, ErrorResult?` | Definir gangue principal |
| `GetJobs` | - | `table` | Obter todos os trabalhos |
| `GetGangs` | - | `table` | Obter todas as gangues |
| `AddMoney` | `identifier, moneyType, amount, reason?` | `boolean` | Adicionar dinheiro |
| `RemoveMoney` | `identifier, moneyType, amount, reason?` | `boolean` | Remover dinheiro |
| `SetMoney` | `identifier, moneyType, amount, reason?` | `boolean` | Definir dinheiro |
| `SetMetadata` | `identifier, metadata, value` | - | Definir metadata |
| `GetMetadata` | `identifier, metadata` | `any` | Obter metadata |
| `CreatePlayerVehicle` | `request` | `integer?, ErrorResult?` | Criar veículo |
| `GetPlayerVehicle` | `vehicleId, filters?` | `PlayerVehicle?` | Obter veículo específico |
| `GetPlayerVehicles` | `filters?` | `PlayerVehicle[]` | Obter veículos do jogador |
| `SetPlayerVehicleOwner` | `vehicleId, citizenid` | `boolean, ErrorResult?` | Alterar dono |
| `DeletePlayerVehicles` | `idType, idValue` | `boolean` | Deletar veículos |
| `SaveVehicle` | `vehicle, options` | `boolean, ErrorResult?` | Salvar estado do veículo |

### Client Exports

| Export | Parâmetros | Retorno | Descrição |
|--------|------------|--------|-------------|
| `GetVehiclesByName` | `key?` | `table` | Obter veículos por nome |
| `GetVehiclesByHash` | `key?` | `table` | Obter veículos por hash |
| `GetVehiclesByCategory` | - | `table` | Obter veículos por categoria |
| `GetWeapons` | `key?` | `table` | Obter dados de armas |

## Eventos

### Server Events

| Evento | Payload | Descrição |
|-------|----------|-------------|
| `QBCore:Server:OnPlayerLoaded` | `source` | Disparado quando o jogador carrega |
| `QBCore:Server:OnPlayerUnload` | `source` | Disparado quando o jogador descarrega |
| `QBCore:Server:OnJobUpdate` | `source, job` | Disparado na atualização de trabalho |
| `QBCore:Server:OnGangUpdate` | `source, gang` | Disparado na atualização de gangue |
| `QBCore:Server:OnMoneyChange` | `source, moneyType, amount, actionType, reason` | Disparado na alteração de dinheiro |
| `qbx_core:server:onGroupUpdate` | `source, groupName, grade` | Disparado na atualização de grupo |
| `qbx_core:server:playerLoggedOut` | `source` | Disparado no logout |

### Client Events

| Evento | Payload | Descrição |
|-------|----------|-------------|
| `QBCore:Client:OnPlayerLoaded` | - | Disparado quando o jogador carrega |
| `QBCore:Client:OnPlayerUnload` | - | Disparado quando o jogador descarrega |
| `QBCore:Client:OnJobUpdate` | `job` | Disparado na atualização de trabalho |
| `QBCore:Client:OnGangUpdate` | `gang` | Disparado na atualização de gangue |
| `qbx_core:client:playerLoggedOut` | - | Disparado no logout |
| `qbx_core:client:onSetMetaData` | `metadata, oldValue, newValue` | Disparado na alteração de metadata |

## Estrutura de Arquivos

```
qbx_core/
├── client/
│   ├── main.lua           # Inicialização, dados de veículos, exports
│   ├── groups.lua          # Gerenciamento de grupos
│   ├── functions.lua       # Funções utilitárias
│   ├── loops.lua           # Loops do client
│   ├── events.lua          # Handlers de eventos
│   ├── character.lua       # Gerenciamento de personagem
│   ├── discord.lua         # Discord rich presence
│   └── bridge/qb/         # Ponte de compatibilidade QB
├── server/
│   ├── main.lua           # Inicialização, exports, jogadores
│   ├── player.lua         # Dados do jogador, trabalhos, gangues
│   ├── groups.lua          # Gerenciamento de grupos
│   ├── commands.lua        # Comandos admin/jogador
│   ├── character.lua       # Criação de personagem
│   └── storage.lua         # Banco de dados
├── shared/
│   ├── jobs.lua           # Definições de trabalhos
│   ├── gangs.lua          # Definições de gangues
│   ├── items.lua           # Definições de itens
│   ├── vehicles.lua       # Dados de veículos
│   └── weapons.lua        # Dados de armas
├── modules/
│   ├── lib.lua            # Funções da biblioteca
│   ├── logger.lua         # Módulo de logging
│   ├── hooks.lua          # Sistema de hooks
│   └── playerdata.lua     # Dados do jogador
└── config/                # Arquivos de configuração
```

## Dependências

| Dependência | Versão Mínima | Obrigatória |
|------------|-------------------|----------|
| ox_lib | 3.20.0 | ✅ |
| oxmysql | - | ✅ |
| ox_inventory | 2.42.1 | ✅ |
| OneSync Infinity | - | ✅ |

## Solução de Problemas

### Jogador não consegue fazer login
- Verifique se o banco de dados está rodando
- Confirme se o oxmysql está iniciado antes do qbx_core
- Verifique os logs do servidor para erros de banco de dados

### Trabalho/gangue não atualiza
- Verifique se o evento `OnJobUpdate`/`OnGangUpdate` está sendo disparado
- Confirme se o jogador está online ao usar exports de servidor

### Metadados não salvam
- Verifique se o campo existe na tabela players
- Confirme se o tipo de dado é compatível
- Use `SetMetadata` ao invés de alterar diretamente

### Erro de compatibilidade QB
- O qbx_core usa ponte QB em `client/bridge/qb/` e `server/bridge/qb/`
- Verifique se os eventos QBCore estão sendo disparados corretamente
