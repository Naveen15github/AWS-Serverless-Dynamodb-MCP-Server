# JSON Configuration Files Migration Notes

## What Changed

All JSON configuration files have been moved to the `configs/` folder for better organization.

## Moved Files

The following files were moved to `configs/`:

1. `mcp-config-fixed.json` → `configs/mcp-config-fixed.json`
2. `mcp-config-powershell.json` → `configs/mcp-config-powershell.json`
3. `test-output.json` → `configs/test-output.json`
4. `02-proxy/claude_desktop_config_sh.json` → `configs/claude_desktop_config_sh.json`

## Generated Files

The deployment scripts now generate configuration files directly in the `configs/` folder:

- **`apply.sh`** generates → `configs/claude_desktop_config_sh.json`
- **`scripts-powershell/apply.ps1`** generates → `configs/claude_desktop_config_sh.json`

## Updated References

The following files have been updated to reference the new location:

- ✅ `apply.sh` - Now outputs to `configs/claude_desktop_config_sh.json`
- ✅ `scripts-powershell/apply.ps1` - Now outputs to `configs/claude_desktop_config_sh.json`
- ✅ `README.md` - Updated configuration instructions
- ✅ `FILE-ORGANIZATION.md` - Updated file locations

## How to Use

### After Deployment

The generated configuration file will be at:
```
configs/claude_desktop_config_sh.json
```

### Copy to Claude Desktop

```bash
# View the generated config
cat configs/claude_desktop_config_sh.json

# Or on Windows
type configs\claude_desktop_config_sh.json
```

Then copy the contents to your Claude Desktop config file:
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Mac**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

## Benefits

1. **Centralized Configuration** - All config files in one place
2. **Cleaner Project Structure** - Separated configs from code
3. **Easier to Find** - All JSON files in dedicated folder
4. **Better Security** - Easier to add `configs/` to .gitignore if needed

## No Breaking Changes

All scripts have been updated to use the new location. Simply run the deployment scripts as usual:

```bash
# Linux/Mac
./apply.sh

# Windows
.\scripts-powershell\apply.ps1
```

The configuration will be generated in the correct location automatically.
