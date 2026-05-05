# PowerShell Scripts Migration Notes

## What Changed

All PowerShell scripts (`.ps1` files) have been moved from the project root to the `scripts-powershell/` folder for better organization.

## Moved Files

The following files were moved from root to `scripts-powershell/`:

1. `apply.ps1` → `scripts-powershell/apply.ps1`
2. `check_env.ps1` → `scripts-powershell/check_env.ps1`
3. `check_env_simple.ps1` → `scripts-powershell/check_env_simple.ps1`
4. `check_env_v2.ps1` → `scripts-powershell/check_env_v2.ps1`
5. `fix-time.ps1` → `scripts-powershell/fix-time.ps1`
6. `sync-time-and-retry.ps1` → `scripts-powershell/sync-time-and-retry.ps1`
7. `test-output.ps1` → `scripts-powershell/test-output.ps1`
8. `test-proxy.ps1` → `scripts-powershell/test-proxy.ps1`
9. `update-mcp-config.ps1` → `scripts-powershell/update-mcp-config.ps1`
10. `validate.ps1` → `scripts-powershell/validate.ps1`

## Not Moved

- `02-proxy/proxy.ps1` - Remains in the proxy folder as it's part of the proxy infrastructure

## How to Use

### Option 1: Run from project root
```powershell
.\scripts-powershell\apply.ps1
.\scripts-powershell\check_env.ps1
.\scripts-powershell\validate.ps1
```

### Option 2: Change to scripts folder first
```powershell
cd scripts-powershell
.\apply.ps1
.\check_env.ps1
.\validate.ps1
```

## Updated Documentation

The following files have been updated to reflect the new structure:
- ✅ `README.md` - Updated project structure and quick start sections
- ✅ `FILE-ORGANIZATION.md` - Updated file locations
- ✅ `scripts-powershell/README.md` - Created new documentation for PowerShell scripts

## Benefits

1. **Better Organization** - All PowerShell scripts in one place
2. **Cleaner Root Directory** - Reduced clutter in project root
3. **Platform Separation** - Clear separation between bash scripts (root) and PowerShell scripts (scripts-powershell/)
4. **Easier Navigation** - All Windows-specific scripts in one folder

## No Breaking Changes

All scripts work exactly the same way, just from a different location. Simply update your command paths to include `scripts-powershell\`.
