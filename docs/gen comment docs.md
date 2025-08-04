# Lua Documentation Style Guide (Docstring-based)

Standardized doc comment format for documenting Lua modules and APIs using multiline annotations.

---

## 💡 Format
Use `--[=[ ... ]=]` for multiline doc comments.
Avoid using single-line `--` for documentation purposes.

---

## 🧱 Structure

### Top Modudle Description

```lua
--[=[
	@class ModuleName@1.0.0
	Description of the module
]=]
```

### Class Declaration
```lua
--[=[
	@class ClassName
	Description of the module or class.
]=]
```

### Type Definition
```lua
--[=[
	@type TypeName
	@within ClassName
	@field FieldName Type Description
	@field OptionalField? Type Optional description
]=]
```

### Method or Function Documentation
> Place directly above the method.  
> ⚠️ Do **not** include `@function` in function-level blocks.

```lua
--[=[
	@within ClassName
	@param paramName ParamType(default value) -- Description of the parameter
	@return ReturnType Description of the return value

	Multiline description of the method or function.
]=]
function ClassName:MethodName(...)
```

---

## 🔖 Tags (Optional and Supported)
- `@class` — Declares a class/module
- `@type` — Declares a type alias or structure
- `@param` — Describes a parameter
- `@return` — Describes return values
- `@within` — Groups the function/type under a class/module
- `@tag` — Semantic tags like:
  - `Event`
  - `Constructor`
  - `Client`, `Server`

---

## ✅ Conventions
- Use exactly one doc block per item (class/type/function).
- Do not duplicate `@function` for every method.
- Use `@within` in every type/function block for nesting clarity.
- Avoid inline comments (`--`) for API documentation.
- Optional `@example` blocks may follow if needed.

---

## 🛠 Compatibility
This format is compatible with:
- LuneDocs
- Dash
- Roblox Language Server (LuaLS)
- Stylua / Selene
- ChatGPT / GitHub Copilot / Cody and other AI tools