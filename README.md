# Eznotes.nvim
This is an nvim plugin made with lua.
It's purpose is to offer a simple an easy way to take some simple notes.

## Instalation

### Lazy

```lua
{
    "PKerty/eznotes.nvim"
    config = function()
        require("eznotes").setup()
    end
}
```

## Usage
**Available commands**:
- `EznotesCreateNote`
- `EznotesListNotes`
- `EznotesCleanDir`

## Opts
This plugin only option is the file were the notes will be saved. Since it was intended as temporary post its. The default path is `/tmp/eznotes`, if the dir doesn't exist, it's created. But modification of this behaviour is supported:

```lua
{
    load_path = "/tmp/eznotes"
}
```
