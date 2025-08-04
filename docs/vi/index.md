# RbxUtils Documentation

Chào mừng đến với tài liệu RbxUtils - một bộ sưu tập các tiện ích mạnh mẽ cho Roblox development.

## Tổng quan

RbxUtils cung cấp các module và tiện ích để giúp bạn phát triển game Roblox hiệu quả hơn. Bao gồm:

- **Structure System**: Hệ thống quản lý và đồng bộ dữ liệu giữa server-client
- **Type System**: Hệ thống kiểu dữ liệu mạnh mẽ
- Và nhiều tiện ích khác...

## Bắt đầu nhanh

### Cài đặt

1. Clone repository này vào dự án Roblox của bạn
2. Sử dụng Rojo để sync code vào Roblox Studio
3. Require các module cần thiết trong script của bạn

### Ví dụ cơ bản

```lua
local Structure = require(ReplicatedStorage.Systems.Structure)

-- Tạo structure để quản lý dữ liệu game
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
Hệ thống mạnh mẽ để bind và đồng bộ dữ liệu table với Configuration instances, hỗ trợ quan sát thay đổi real-time.

## Yêu cầu hệ thống

- Roblox Studio
- Rojo (khuyến nghị)
- Aftman (cho dependency management)

## Đóng góp

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Xem file [LICENSE.md](../LISENCE.vi.md) để biết thêm chi tiết.
