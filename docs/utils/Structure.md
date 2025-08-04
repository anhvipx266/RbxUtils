# Structure System

The Structure module provides powerful utilities for binding table data to `Configuration` instances (binder) and observing/reading structured data (reader). It enables seamless data synchronization between server and client in Roblox games.

## Overview

The Structure system offers:
- **Data Binding**: Bind table data to Configuration instances on the server
- **Data Reading**: Read and observe data from Configuration instances on the client  
- **Deep Nesting**: Support for nested structures with configurable depth
- **Auto-Synchronization**: Automatic data sync between server and client
- **Type Safety**: Support for Roblox's basic data types
- **Real-time Updates**: Live observation of data changes

## Supported Data Types

Structure supports the following data types with automatic conversion:

| Lua Type | Roblox ValueBase |
|----------|------------------|
| `string` | `StringValue` |
| `number` (integer) | `IntValue` |
| `number` (decimal) | `NumberValue` |
| `boolean` | `BoolValue` |
| `Instance` | `ObjectValue` |
| `CFrame` | `CFrameValue` |
| `Vector3` | `Vector3Value` |
| `Color3` | `Color3Value` |
| `table` | `Configuration` (nested) |

## Architecture

### Core Classes

#### Structure
Base class providing common functionality for all structure types.

#### StructureBinder
Server-side class for binding table data to Configuration instances.

#### StructureReader
Client-side class for reading and observing data from Configuration instances.

#### ValueStructureBinder
Specialized binder using ValueBase instances as keys.

#### ValueStructureReader
Corresponding reader for ValueStructureBinder.

## API Documentation

### Structure.binder()
```lua
Structure.binder(dataTable: table, config: Configuration, deepLevel: number?) -> StructureBinder
```

Creates a StructureBinder instance to bind a table to a Configuration.

**Parameters:**
- `dataTable` - Table containing data to bind
- `config` - Configuration instance to bind to
- `deepLevel` - Maximum depth for nested tables (default: 100)

**Returns:** StructureBinder instance

**Example:**
```lua
local config = Instance.new("Configuration")
config.Name = "PlayerData"
config.Parent = game.ReplicatedStorage

local playerData = {
    name = "PlayerOne",
    level = 15,
    inventory = {
        coins = 1000,
        items = {"sword", "shield"}
    },
    position = Vector3.new(0, 10, 0)
}

local binder = Structure.binder(playerData, config)

-- Update data (automatically syncs to clients)
binder.level = 16
binder.inventory.coins = 1100
```

### Structure.reader()
```lua
Structure.reader(config: Configuration, deepLevel: number?, meta: StructureReader?) -> StructureReader
```

Creates a StructureReader instance to read data from a Configuration.

**Parameters:**
- `config` - Configuration instance to read from
- `deepLevel` - Maximum depth for nested structures (default: 100)
- `meta` - Custom metatable (optional)

**Returns:** StructureReader instance

**Example:**
```lua
-- Client-side
local config = game.ReplicatedStorage:WaitForChild("PlayerData")
local reader = Structure.reader(config)

-- Read current data
print("Player name:", reader.name)
print("Player level:", reader.level)
print("Coins:", reader.inventory.coins)
```

### Structure.fromSkeleton()
```lua
Structure.fromSkeleton(
    dataTable: table, 
    config: Configuration, 
    skeleton: table, 
    deepLevel: number?, 
    meta: StructureBinder?
) -> StructureBinder
```

Binds a table according to a predefined skeleton structure.

**Parameters:**
- `dataTable` - Actual data to bind
- `config` - Configuration instance
- `skeleton` - Skeleton structure definition
- `deepLevel` - Maximum depth
- `meta` - Custom metatable

**Example:**
```lua
local skeleton = {
    player = {
        stats = {
            health = 0,
            mana = 0
        },
        settings = {
            volume = 0.5,
            graphics = "medium"
        }
    }
}

local data = {
    player = {
        stats = {
            health = 100,
            mana = 50
        },
        settings = {
            volume = 0.8,
            graphics = "high"
        }
    }
}

local binder = Structure.fromSkeleton(data, config, skeleton)
```

### Structure.bridger()
```lua
Structure.bridger(
    dataTable: table, 
    config: Configuration, 
    skeleton: table, 
    deepLevel: number?
) -> StructureBinder | StructureReader
```

Creates a binder on server or reader on client automatically based on context.

**Example:**
```lua
-- This code works on both server and client
local bridger = Structure.bridger(data, config, skeleton)

-- On server: returns StructureBinder
-- On client: returns StructureReader
```

## StructureBinder Methods

### Set()
```lua
binder:Set(tb: table) -> ()
```

Replaces all current data with a new table, clearing existing bindings.

**Example:**
```lua
binder:Set({
    newField = "value",
    anotherField = 42,
    nested = {
        data = true
    }
})
```

### Destroy()
```lua
binder:Destroy() -> ()
```

Cleans up resources and destroys all bound instances.

## StructureReader Methods

### OnChange()
```lua
reader:OnChange(callback: CallbackFnc) -> ()
```

Registers a callback to be called when the structure changes.

**Example:**
```lua
reader:OnChange(function(key, value)
    print("Data changed:", key, "->", value)
end)
```

### Observe()
```lua
reader:Observe(onNew: AddOrDesCallback?, onDes: AddOrDesCallback?) -> ()
```

Observes when new keys are added or existing keys are removed.

**Example:**
```lua
reader:Observe(
    function(key) 
        print("New key added:", key) 
    end,
    function(key) 
        print("Key removed:", key) 
    end
)
```

### ObserveKey()
```lua
reader:ObserveKey(key: string, callback: ValueCallbackFnc) -> ()
```

Observes changes to a specific key.

**Example:**
```lua
reader:ObserveKey("level", function(newLevel)
    print("Player leveled up to:", newLevel)
    updateLevelUI(newLevel)
end)
```

### OnPairs()
```lua
reader:OnPairs(callback: CallbackFnc) -> ()
```

Registers a callback for each existing and new key-value pair.

**Example:**
```lua
reader:OnPairs(function(key, value)
    print("Processing pair:", key, "=", value)
end)
```

### Raw()
```lua
reader:Raw() -> table
```

Returns the raw table data without Structure wrapper.

### Wait()
```lua
reader:Wait(k: string) -> any
```

Waits for a key to appear (maximum 30 seconds timeout).

**Example:**
```lua
local importantData = reader:Wait("missionData")
print("Mission data received:", importantData)
```

## Complete Examples

### Server Implementation
```lua
local Structure = require(ReplicatedStorage.Systems.Structure)

-- Game state data
local gameState = {
    round = 1,
    timeRemaining = 300,
    status = "waiting",
    players = {},
    leaderboard = {
        top3 = {}
    }
}

-- Create Configuration in ReplicatedStorage
local gameConfig = Instance.new("Configuration")
gameConfig.Name = "GameState"
gameConfig.Parent = game.ReplicatedStorage

-- Bind the data
local gameBinder = Structure.binder(gameState, gameConfig)

-- Game logic updates
game.Players.PlayerAdded:Connect(function(player)
    gameBinder.players[player.Name] = {
        score = 0,
        kills = 0,
        deaths = 0,
        joinTime = os.time()
    }
end)

game.Players.PlayerRemoving:Connect(function(player)
    gameBinder.players[player.Name] = nil
end)

-- Update game state
local function startNewRound()
    gameBinder.round = gameBinder.round + 1
    gameBinder.timeRemaining = 300
    gameBinder.status = "active"
    
    -- Reset player scores
    for playerName, playerData in gameBinder.players do
        playerData.score = 0
        playerData.kills = 0
        playerData.deaths = 0
    end
end
```

### Client Implementation
```lua
local Structure = require(ReplicatedStorage.Systems.Structure)
local Players = game:GetService("Players")

-- Read game state from server
local gameConfig = game.ReplicatedStorage:WaitForChild("GameState")
local gameReader = Structure.reader(gameConfig)

-- UI References
local gameUI = Players.LocalPlayer.PlayerGui:WaitForChild("GameUI")
local roundLabel = gameUI.RoundLabel
local timerLabel = gameUI.TimerLabel
local leaderboardFrame = gameUI.LeaderboardFrame

-- Observe round changes
gameReader:ObserveKey("round", function(newRound)
    roundLabel.Text = "Round " .. newRound
    print("Starting round", newRound)
end)

-- Observe timer changes
gameReader:ObserveKey("timeRemaining", function(timeLeft)
    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
    
    if timeLeft <= 10 then
        timerLabel.TextColor3 = Color3.new(1, 0, 0) -- Red warning
    else
        timerLabel.TextColor3 = Color3.new(1, 1, 1) -- White
    end
end)

-- Observe player data changes
gameReader.players:OnChange(function(playerName, playerData)
    if playerData then
        updatePlayerInLeaderboard(playerName, playerData)
    else
        removePlayerFromLeaderboard(playerName)
    end
end)

-- Observe game status
gameReader:ObserveKey("status", function(status)
    if status == "waiting" then
        showWaitingScreen()
    elseif status == "active" then
        showGameScreen()
    elseif status == "ended" then
        showEndScreen()
    end
end)

-- Helper functions
function updatePlayerInLeaderboard(playerName, playerData)
    local playerFrame = leaderboardFrame:FindFirstChild(playerName)
    if not playerFrame then
        playerFrame = leaderboardFrame.PlayerTemplate:Clone()
        playerFrame.Name = playerName
        playerFrame.Visible = true
        playerFrame.Parent = leaderboardFrame
    end
    
    playerFrame.PlayerName.Text = playerName
    playerFrame.Score.Text = tostring(playerData.score)
    playerFrame.KD.Text = string.format("%d/%d", playerData.kills, playerData.deaths)
end

function removePlayerFromLeaderboard(playerName)
    local playerFrame = leaderboardFrame:FindFirstChild(playerName)
    if playerFrame then
        playerFrame:Destroy()
    end
end
```

### Advanced Usage with Skeleton
```lua
-- Define a complex game data structure
local gameDataSkeleton = {
    settings = {
        gameplay = {
            roundTime = 300,
            maxPlayers = 16,
            friendlyFire = false
        },
        graphics = {
            quality = "medium",
            shadows = true,
            particleEffects = true
        }
    },
    match = {
        teams = {
            red = {
                players = {},
                score = 0,
                color = Color3.new(1, 0, 0)
            },
            blue = {
                players = {},
                score = 0,
                color = Color3.new(0, 0, 1)
            }
        },
        powerups = {},
        events = {}
    }
}

-- Initialize with default data
local defaultGameData = {
    settings = {
        gameplay = {
            roundTime = 600,
            maxPlayers = 20,
            friendlyFire = true
        },
        graphics = {
            quality = "high",
            shadows = true,
            particleEffects = true
        }
    },
    match = {
        teams = {
            red = {
                players = {"Player1", "Player2"},
                score = 0,
                color = Color3.new(1, 0, 0)
            },
            blue = {
                players = {"Player3", "Player4"},
                score = 0,
                color = Color3.new(0, 0, 1)
            }
        },
        powerups = {
            "speed_boost",
            "shield"
        },
        events = {}
    }
}

local config = Instance.new("Configuration")
config.Name = "AdvancedGameData"
config.Parent = game.ReplicatedStorage

local advancedBinder = Structure.fromSkeleton(
    defaultGameData, 
    config, 
    gameDataSkeleton, 
    5  -- Limit depth to 5 levels
)

-- Update nested data
advancedBinder.settings.gameplay.roundTime = 450
advancedBinder.match.teams.red.score = 10
table.insert(advancedBinder.match.powerups, "health_pack")
```

## Best Practices

### Performance Optimization
1. **Limit Deep Level**: Use appropriate `deepLevel` values to prevent performance issues with overly deep structures.
   ```lua
   -- Good: Reasonable depth
   local binder = Structure.binder(data, config, 3)
   
   -- Avoid: Excessive depth
   local binder = Structure.binder(data, config, 50)
   ```

2. **Batch Updates**: When making multiple changes, batch them to reduce network traffic.
   ```lua
   -- Good: Batch updates
   local newData = {
       health = 100,
       mana = 50,
       level = 10
   }
   binder:Set(newData)
   
   -- Avoid: Individual updates
   binder.health = 100
   binder.mana = 50
   binder.level = 10
   ```

### Memory Management
1. **Always Destroy**: Call `Destroy()` when structures are no longer needed.
   ```lua
   local binder = Structure.binder(data, config)
   
   -- When done
   binder:Destroy()
   ```

2. **Avoid Memory Leaks**: Be careful with circular references in callback functions.

### Error Handling
1. **Use pcall**: Wrap Structure operations in pcall for production code.
   ```lua
   local success, result = pcall(function()
       return Structure.binder(data, config)
   end)
   
   if not success then
       warn("Failed to create structure binder:", result)
   end
   ```

2. **Validate Data Types**: Ensure data types are supported before binding.
   ```lua
   local function isValidDataType(value)
       local valueType = typeof(value)
       return valueType == "string" 
           or valueType == "number" 
           or valueType == "boolean"
           or valueType == "Instance"
           or valueType == "CFrame"
           or valueType == "Vector3"
           or valueType == "Color3"
           or type(value) == "table"
   end
   ```

### Code Organization
1. **Separate Concerns**: Keep binder logic on server, reader logic on client.

2. **Use Modules**: Organize Structure usage in dedicated modules.
   ```lua
   -- DataManager.lua (Server)
   local DataManager = {}
   
   function DataManager.createPlayerBinder(player, data)
       local config = Instance.new("Configuration")
       config.Name = player.Name .. "_Data"
       config.Parent = game.ReplicatedStorage.PlayerData
       
       return Structure.binder(data, config)
   end
   
   return DataManager
   ```

## Limitations and Considerations

### Data Type Limitations
- Only supports Roblox's basic data types
- No support for functions or coroutines
- Tables with circular references are not supported

### Performance Considerations
- Deep nesting can impact performance
- Large datasets may cause network congestion
- Frequent updates can overwhelm the replication system

### Network Limitations
- Attributes have size limitations
- Too many ValueBase instances can impact performance
- Consider using RemoteEvents for large data transfers

### Error Scenarios
- Invalid data types will throw errors
- Destroyed Configuration instances will break readers
- Network issues can cause desynchronization

## Troubleshooting

### Common Issues

1. **"Unsupported value type" Error**
   ```lua
   -- Problem: Unsupported data type
   binder.functionValue = function() end -- Error!
   
   -- Solution: Use only supported types
   binder.stringValue = "text"
   binder.numberValue = 42
   ```

2. **Memory Leaks**
   ```lua
   -- Problem: Not destroying structures
   local binder = Structure.binder(data, config)
   -- Never call binder:Destroy()
   
   -- Solution: Always clean up
   binder:Destroy()
   ```

3. **Synchronization Issues**
   ```lua
   -- Problem: Reading data before it's ready
   local reader = Structure.reader(config)
   print(reader.playerName) -- Might be nil
   
   -- Solution: Use Wait() or observe changes
   local playerName = reader:Wait("playerName")
   -- or
   reader:ObserveKey("playerName", function(name)
       print("Player name:", name)
   end)
   ```

### Debug Tips

1. **Enable Verbose Logging**
   ```lua
   reader:OnChange(function(key, value)
       print("DEBUG: Structure changed -", key, ":", value)
   end)
   ```

2. **Check Configuration Structure**
   ```lua
   local function printConfigStructure(config, indent)
       indent = indent or ""
       print(indent .. config.Name .. " (" .. config.ClassName .. ")")
       
       for _, child in config:GetChildren() do
           if child:IsA("Configuration") then
               printConfigStructure(child, indent .. "  ")
           else
               print(indent .. "  " .. child.Name .. " = " .. tostring(child.Value))
           end
       end
   end
   
   printConfigStructure(game.ReplicatedStorage.GameData)
   ```

This comprehensive documentation should help developers understand and effectively use the Structure system in their Roblox projects.