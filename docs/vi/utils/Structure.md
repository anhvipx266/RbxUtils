# Structure

Structure là một module mạnh mẽ cung cấp các tiện ích để bind dữ liệu table với các instance `Configuration` (binder), và để quan sát và đọc dữ liệu có cấu trúc (reader).

## Tổng quan

Module Structure hỗ trợ:
- **Binding**: Liên kết dữ liệu table với Configuration instances trên server
- **Reading**: Đọc và quan sát dữ liệu từ Configuration instances trên client
- **Deep nesting**: Hỗ trợ nested structures với độ sâu có thể cấu hình
- **Auto-sync**: Tự động đồng bộ dữ liệu giữa server và client
- **Type safety**: Hỗ trợ các kiểu dữ liệu Roblox cơ bản

## Các kiểu dữ liệu được hỗ trợ

Structure hỗ trợ các kiểu dữ liệu sau:
- `string` → `StringValue`
- `number` (integer) → `IntValue`
- `number` (float) → `NumberValue`  
- `boolean` → `BoolValue`
- `Instance` → `ObjectValue`
- `CFrame` → `CFrameValue`
- `Vector3` → `Vector3Value`
- `Color3` → `Color3Value`
- `table` → `Configuration` (nested structure)

## Classes

### Structure
Lớp cơ sở cung cấp các chức năng chung.

### StructureBinder
Lớp dành cho server để bind dữ liệu table vào Configuration instances.

### StructureReader  
Lớp dành cho client để đọc và quan sát dữ liệu từ Configuration instances.

### ValueStructureBinder
Lớp binder đặc biệt sử dụng ValueBase instances làm keys.

### ValueStructureReader
Lớp reader tương ứng với ValueStructureBinder.

## API Reference

### Structure.binder()
```lua
Structure.binder(dataTable: table, config: Configuration, deepLevel: number?) -> StructureBinder
```
Tạo một StructureBinder instance để bind table vào Configuration.

**Parameters:**
- `dataTable`: Table chứa dữ liệu cần bind
- `config`: Configuration instance để bind vào
- `deepLevel`: Độ sâu tối đa cho nested tables (mặc định: 100)

**Returns:** StructureBinder instance

**Ví dụ:**
```lua
local config = Instance.new("Configuration")
config.Parent = workspace

local data = {
    playerName = "John",
    level = 10,
    stats = {
        health = 100,
        mana = 50
    }
}

local binder = Structure.binder(data, config)
binder.playerName = "Jane"  -- Tự động cập nhật Configuration
```

### Structure.reader()
```lua
Structure.reader(config: Configuration, deepLevel: number?, meta: StructureReader?) -> StructureReader
```
Tạo một StructureReader instance để đọc dữ liệu từ Configuration.

**Parameters:**
- `config`: Configuration instance để đọc từ
- `deepLevel`: Độ sâu tối đa cho nested structures (mặc định: 100)
- `meta`: Metatable tùy chỉnh (tùy chọn)

**Returns:** StructureReader instance

**Ví dụ:**
```lua
local config = workspace:FindFirstChild("PlayerData")
local reader = Structure.reader(config)

-- Đọc dữ liệu
print(reader.playerName)  -- "Jane"
print(reader.stats.health)  -- 100
```

### Structure.fromSkeleton()
```lua
Structure.fromSkeleton(dataTable: table, config: Configuration, skeleton: table, deepLevel: number?, meta: StructureBinder?) -> StructureBinder
```
Bind table theo một skeleton structure được định nghĩa trước.

**Parameters:**
- `dataTable`: Dữ liệu thực tế
- `config`: Configuration instance
- `skeleton`: Cấu trúc skeleton
- `deepLevel`: Độ sâu tối đa
- `meta`: Metatable tùy chỉnh

### Structure.bridger()
```lua
Structure.bridger(dataTable: table, config: Configuration, skeleton: table, deepLevel: number?) -> StructureBinder | StructureReader
```
Tạo binder trên server hoặc reader trên client tự động.

**Ví dụ:**
```lua
-- Code này hoạt động trên cả server và client
local bridger = Structure.bridger(data, config, skeleton)

-- Trên server: trả về StructureBinder
-- Trên client: trả về StructureReader
```

## StructureBinder Methods

### Set()
```lua
binder:Set(tb: table) -> ()
```
Thay thế toàn bộ dữ liệu hiện tại bằng table mới.

**Ví dụ:**
```lua
binder:Set({
    newData = "value",
    anotherField = 123
})
```

## StructureReader Methods

### OnChange()
```lua
reader:OnChange(callback: CallbackFnc) -> ()
```
Đăng ký callback được gọi khi structure thay đổi.

**Ví dụ:**
```lua
reader:OnChange(function(key, value)
    print("Changed:", key, "to", value)
end)
```

### Observe()
```lua
reader:Observe(onNew: AddOrDesCallback?, onDes: AddOrDesCallback?) -> ()
```
Quan sát khi có key mới được thêm hoặc bị xóa.

**Ví dụ:**
```lua
reader:Observe(
    function(key) print("New key:", key) end,
    function(key) print("Removed key:", key) end
)
```

### ObserveKey()
```lua
reader:ObserveKey(key: string, callback: ValueCallbackFnc) -> ()
```
Quan sát một key cụ thể.

**Ví dụ:**
```lua
reader:ObserveKey("playerName", function(value)
    print("Player name changed to:", value)
end)
```

### OnPairs()
```lua
reader:OnPairs(callback: CallbackFnc) -> ()
```
Đăng ký callback cho mỗi cặp key-value hiện có và mới.

**Ví dụ:**
```lua
reader:OnPairs(function(key, value)
    print("Key-value pair:", key, value)
end)
```

### Raw()
```lua
reader:Raw() -> table
```
Lấy raw table data.

### Wait()
```lua
reader:Wait(k: string) -> any
```
Đợi cho đến khi key xuất hiện (tối đa 30 giây).

**Ví dụ:**
```lua
local value = reader:Wait("importantData")
print("Got important data:", value)
```

### Destroy()
```lua
structure:Destroy() -> ()
```
Dọn dẹp tài nguyên và ngắt kết nối.

## Ví dụ hoàn chỉnh

### Server (Binder)
```lua
local Structure = require(ReplicatedStorage.Systems.Structure)

-- Tạo dữ liệu game
local gameData = {
    round = 1,
    timeLeft = 300,
    players = {
        ["Player1"] = {
            score = 100,
            kills = 5
        },
        ["Player2"] = {
            score = 80,
            kills = 3
        }
    }
}

-- Tạo Configuration trong ReplicatedStorage
local config = Instance.new("Configuration")
config.Name = "GameData"
config.Parent = game.ReplicatedStorage

-- Bind dữ liệu
local binder = Structure.binder(gameData, config)

-- Cập nhật dữ liệu (sẽ tự động sync đến client)
binder.round = 2
binder.timeLeft = 299
binder.players["Player1"].score = 110
```

### Client (Reader)
```lua
local Structure = require(ReplicatedStorage.Systems.Structure)

-- Đọc dữ liệu từ server
local config = game.ReplicatedStorage:WaitForChild("GameData")
local reader = Structure.reader(config)

-- Quan sát thay đổi
reader:OnChange(function(key, value)
    if key == "round" then
        print("New round:", value)
    elseif key == "timeLeft" then
        updateTimerUI(value)
    end
end)

-- Quan sát players
reader.players:OnChange(function(playerName, playerData)
    updatePlayerScore(playerName, playerData.score)
end)

-- Đọc dữ liệu hiện tại
print("Current round:", reader.round)
print("Time left:", reader.timeLeft)
```

## Best Practices

1. **Deep Level**: Sử dụng `deepLevel` hợp lý để tránh hiệu suất kém với structures quá sâu.

2. **Memory Management**: Luôn gọi `Destroy()` khi không cần thiết để giải phóng memory.

3. **Error Handling**: Sử dụng `pcall` khi cần thiết vì một số operations có thể fail.

4. **Type Safety**: Chỉ sử dụng các kiểu dữ liệu được hỗ trợ để tránh lỗi.

5. **Performance**: Với dữ liệu lớn, cân nhắc chia nhỏ thành nhiều Configuration instances.

## Limitations

- Chỉ hỗ trợ các kiểu dữ liệu cơ bản của Roblox
- Không hỗ trợ circular references trong tables
- Deep level có giới hạn để tránh stack overflow
- Attributes có giới hạn về kích thước dữ liệu