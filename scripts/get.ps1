# get.ps1 - one-shot remote bootstrap (runs before the repo exists; depends on nothing in this repo)
# Usage (paste into any shell on a bare machine; stock winget + Windows PowerShell 5.1 suffice):
#   powershell -c "irm https://raw.githubusercontent.com/yu-cn/wdc/main/scripts/get.ps1 | iex"
# Env overrides (set BEFORE the same one-liner; iex cannot pass arguments):
#   $env:WDC_TAG  = 'v0.7.0'                                # pin a release tag (fresh clone only; tag list: GitHub Releases)
#   $env:WDC_REPO = 'https://github.com/you/wdc.git'        # fork users: bootstrap your own repo with the same one-liner
# Chain: ensure winget -> install Git via winget if missing (one UAC prompt; bootstrap elevates anyway)
#        -> locate or clone the repo -> hand over to bootstrap.ps1 (PowerShell 7 setup lives there)
# Constraints: keep this file PURE ASCII - no BOM, no non-ASCII anywhere - so the raw copy survives
#        `irm | iex` under Windows PowerShell 5.1: irm does not strip a BOM, and a leading U+FEFF
#        poisons the string parse (header attributes break it; it also glues the first comment line
#        into a `\uFEFF#` command call). Chinese messages live in bootstrap.ps1, which is
#        file-executed and carries its own BOM. No PS7-only syntax (ternary / ?? / &&).
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }
$repoUrl = if ($env:WDC_REPO) { $env:WDC_REPO } else { 'https://github.com/yu-cn/wdc.git' }
$defaultDir = Join-Path $HOME 'wdc'

function Write-Log { param([string]$Message) Write-Host "[get] $Message" }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log 'winget (App Installer) not found - install it from Microsoft Store ("App Installer") first, then re-run'
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log 'Git not found - installing Git.Git via winget (one UAC prompt, 1-2 minutes)...'
    & winget install -e --id Git.Git --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Git install failed (winget exit code $LASTEXITCODE) - install manually then re-run: winget install Git.Git"
        exit 1
    }
    # winget does not refresh this process PATH: rebuild Machine+User PATH from the registry,
    # probe again, and prepend Git\cmd as a fallback
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
    if (-not (Get-Command git -ErrorAction SilentlyContinue) -and $env:ProgramFiles) {
        $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
        if (Test-Path (Join-Path $gitCmd 'git.exe')) { $env:Path = "$gitCmd;$env:Path" }
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log 'install finished but git.exe is still not found - open a new terminal and re-run'
        exit 1
    }
    Write-Log 'Git ready'
}

# Repo locate: reuse a valid ~/.wdc pointer first (re-run on an existing machine = converge,
# ADR-0004 pattern); default clone to ~\wdc
$repo = $null
$ptr = Join-Path $HOME '.wdc'
if (Test-Path $ptr) {
    $candidate = (Get-Content $ptr -Raw -ErrorAction SilentlyContinue)
    if ($candidate) { $candidate = $candidate.Trim() }
    if ($candidate -and (Test-Path (Join-Path $candidate '.git'))) { $repo = $candidate }
}
if (-not $repo) {
    if (Test-Path $defaultDir) {
        if (Test-Path (Join-Path $defaultDir '.git')) { $repo = $defaultDir }
        else {
            Write-Log "$defaultDir exists but is not a wdc repo - not deleting it; rename or remove it, then re-run"
            exit 1
        }
    } else {
        Write-Log "cloning repo -> $defaultDir"
        & git clone $repoUrl $defaultDir
        if ($LASTEXITCODE -ne 0) {
            Write-Log "clone failed (git exit code $LASTEXITCODE) - check network and re-run"
            exit 1
        }
        if ($env:WDC_TAG) {
            Write-Log "pinning to tag $env:WDC_TAG"
            & git -C $defaultDir checkout $env:WDC_TAG
            if ($LASTEXITCODE -ne 0) {
                Write-Log "checkout $env:WDC_TAG failed - check the tag name against GitHub Releases and re-run"
                exit 1
            }
        }
        $repo = $defaultDir
    }
}

Write-Log "repo ready: $repo - handing over to bootstrap (elevation and PowerShell 7 setup live there)"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'bootstrap.ps1')
exit $LASTEXITCODE
