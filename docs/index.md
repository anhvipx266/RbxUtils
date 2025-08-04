# RbxUtils Documentation

Welcome to RbxUtils documentation - a powerful collection of utilities for Roblox game development.

## Overview

RbxUtils provides modules and utilities to help you develop Roblox games more efficiently. Includes:

- **Structure System**: Data management and synchronization system between server-client
- **Type System**: Powerful type system for Lua/Luau
- And many other utilities...

## Quick Start

### Installation

1. Clone this repository into your Roblox project
2. Use Rojo to sync code into Roblox Studio
3. Require the necessary modules in your scripts

### Basic Example

```lua
local Structure = require(ReplicatedStorage.Systems.Structure)

-- Create structure to manage game data
local gameData = {
    round = 1,
    players = {},
    settings = {
        maxPlayers = 10,
        roundTime = 300
    }
}

local config = Instance.new("Configuration")
config.Name = "GameData"
config.Parent = game.ReplicatedStorage

local binder = Structure.binder(gameData, config)
```

## Modules

### [Structure](utils/Structure.md)
Powerful system for binding and synchronizing table data with Configuration instances, supporting real-time change observation.

## System Requirements

- Roblox Studio
- Rojo (recommended)
- Aftman (for dependency management)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature
4. Make your changes
5. Test thoroughly
6. Submit a pull request

### Code Style

- Follow Luau coding standards
- Use meaningful variable names
- Add JSDoc-style comments for functions
- Include examples in documentation

## Project Structure

```
RbxUtils/
├── src/                    # Source code
│   ├── ReplicatedStorage/  # Shared modules
│   └── ServerScriptService/ # Server-only modules
├── docs/                   # Documentation
├── places/                 # Roblox place files
└── projects/              # Project configurations
```

## API Documentation

Detailed API documentation is available for each module:

- [Structure System](utils/Structure.md) - Data binding and synchronization
- More modules coming soon...

## Examples

### Game State Management
```lua
-- Server
local GameState = require(ReplicatedStorage.Systems.Structure)

local gameConfig = Instance.new("Configuration")
gameConfig.Name = "GameState"
gameConfig.Parent = game.ReplicatedStorage

local gameData = {
    status = "waiting",
    round = 0,
    timeLeft = 0,
    players = {}
}

local gameManager = GameState.binder(gameData, gameConfig)

-- Client
local gameReader = GameState.reader(
    game.ReplicatedStorage:WaitForChild("GameState")
)

gameReader:ObserveKey("status", function(status)
    if status == "active" then
        startGameUI()
    elseif status == "ended" then
        showEndScreen()
    end
end)
```

### Player Data Synchronization
```lua
-- Server
game.Players.PlayerAdded:Connect(function(player)
    local playerConfig = Instance.new("Configuration")
    playerConfig.Name = player.Name
    playerConfig.Parent = game.ReplicatedStorage.PlayerData
    
    local playerData = {
        level = 1,
        experience = 0,
        inventory = {},
        stats = {
            health = 100,
            mana = 50
        }
    }
    
    local playerBinder = Structure.binder(playerData, playerConfig)
    
    -- Update player data
    playerBinder.level = 5
    playerBinder.stats.health = 120
end)
```

## Best Practices

### Performance
- Use appropriate deep levels for nested structures
- Batch data updates when possible
- Clean up unused structures with `:Destroy()`

### Security
- Validate data on server before binding
- Use FilteringEnabled-compliant patterns
- Sanitize user input

### Code Organization
- Separate server and client logic
- Use modules for reusable components
- Follow consistent naming conventions

## Troubleshooting

### Common Issues

**Structure not updating on client:**
- Check if Configuration is properly replicated
- Verify the structure is created on server first
- Ensure proper parent hierarchy

**Memory leaks:**
- Always call `:Destroy()` on unused structures
- Disconnect event connections when done
- Avoid circular references in data

**Performance issues:**
- Limit deep nesting levels
- Use batch updates for multiple changes
- Monitor network traffic

## Support

- **Issues**: [GitHub Issues](https://github.com/anhvipx266/RbxUtils/issues)
- **Discussions**: [GitHub Discussions](https://github.com/anhvipx266/RbxUtils/discussions)
- **Discord**: [Community Server](#) (coming soon)

## License

See [LICENSE.md](../LICENSE.md) for more details.

## Changelog

### v1.0.3
- Improved Structure system performance
- Added comprehensive documentation
- Bug fixes and stability improvements

### v1.0.2
- Initial Structure system implementation
- Basic type system support
- Documentation setup

---

*Built with ❤️ for the Roblox development community*