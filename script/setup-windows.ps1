# ------------------------------------------------------------
#  Workshop setup for Windows
#  Installs: Python 3.14, Node.js, Git, GitHub CLI,
#            Supabase CLI, Vercel CLI and Claude Code.
#  Safe to run more than once - it skips anything already there.
#
#  How to run:  double-click run-setup.bat (it asks for admin rights)
#  Check only:  run-setup.bat -CheckOnly   (installs nothing)
# ------------------------------------------------------------

param([switch]$CheckOnly)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------- Settings you can change ----------
$MinPython   = [version]"3.14"
$WingetPython = "Python.Python.3.14"
$MinNode     = 18
# ---------------------------------------------

$Start   = Get-Date
$Stamp   = $Start.ToString("yyyyMMdd-HHmmss")
$LogFile = Join-Path $env:USERPROFILE "workshop-setup-$Stamp.log"
try { Start-Transcript -Path $LogFile -Force | Out-Null } catch {}

$Results = New-Object System.Collections.ArrayList

function Say($t)  { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "    [OK] $t" -ForegroundColor Green }
function Warn($t) { Write-Host "    [..] $t" -ForegroundColor Yellow }
function Bad($t)  { Write-Host "    [X]  $t" -ForegroundColor Red }
function Record($name, $status, $note = "") {
    [void]$Results.Add([pscustomobject]@{ Name = $name; Status = $status; Note = $note })
}

# Reload PATH so newly installed tools are found without reopening the window
function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path", "User")
    $extra   = @("$env:USERPROFILE\.local\bin", "$env:APPDATA\npm")
    $env:Path = (@($machine, $user) + $extra | Where-Object { $_ }) -join ";"
}

# Add a folder to this user's PATH permanently
function Add-UserPath($dir) {
    if ($CheckOnly) { return }
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $user) { $user = "" }
    if (($user -split ";") -notcontains $dir) {
        [Environment]::SetEnvironmentVariable("Path", ($user.TrimEnd(";") + ";" + $dir).TrimStart(";"), "User")
    }
    Refresh-Path
}

function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Get-Ver($cmd) {
    if (-not (Has $cmd)) { return "" }
    try {
        $out = & $cmd --version 2>$null | Out-String
        if ($out -match '\d+\.\d+(\.\d+)?') { return $Matches[0] }
    } catch {}
    return ""
}

function Winget-Install($id) {
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
    Refresh-Path
}

# Generic installer: Install-Tool "Name" "command" { install steps }
function Install-Tool($name, $cmd, [scriptblock]$installer) {
    Say $name
    if (Has $cmd) {
        Ok "Already installed"
        Record $name "AlreadyInstalled"
    } elseif ($CheckOnly) {
        Bad "Missing (would install)"
        Record $name "Missing"
    } else {
        Warn "Installing..."
        try { & $installer } catch { Bad $_.Exception.Message }
        Refresh-Path
        if (Has $cmd) { Ok "Installed"; Record $name "Installed" }
        else          { Bad "Could not install"; Record $name "Failed" }
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor White
Write-Host "   Vibe Coding Workshop - Windows setup" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
if ($CheckOnly) {
    Write-Host "CHECK-ONLY MODE: nothing will be installed or changed." -ForegroundColor Yellow
} else {
    Write-Host "This takes 5-20 minutes. It may look frozen at times - that's normal."
    Write-Host "Please leave this window open until you see the results table."
}

Refresh-Path

# ---------- winget (Windows' built-in app installer) ----------
Say "Windows app installer (winget)"
$HasWinget = Has "winget"
if ($HasWinget) {
    Ok "Ready"
} else {
    Bad "Not found. Open the Microsoft Store, search 'App Installer', click Update or Get, then run this again."
}

# ---------- 1. Python ----------
Say "Python (need $MinPython or newer)"
$PyVer = $null
foreach ($c in @("python", "py")) {
    if (Has $c) {
        try {
            $v = & $c -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>$null
            if ($v -match '^\d+\.\d+\.\d+$' -and [version]$v -ge $MinPython) { $PyVer = $v; break }
        } catch {}
    }
}
if ($PyVer) {
    Ok "Python $PyVer already installed"
    Record "Python" "AlreadyInstalled"
} elseif ($CheckOnly) {
    Bad "Missing or too old"
    Record "Python" "Missing" "need $MinPython+"
} elseif ($HasWinget) {
    Warn "Installing Python $MinPython..."
    Winget-Install $WingetPython
    foreach ($pyDir in @((Join-Path $env:LOCALAPPDATA "Programs\Python\Python314"), (Join-Path $env:ProgramFiles "Python314"))) {
        if (Test-Path $pyDir) { Add-UserPath $pyDir; Add-UserPath (Join-Path $pyDir "Scripts"); break }
    }
    if ((Get-Ver "python") -match '^3\.(1[4-9]|[2-9]\d)') { Ok "Installed"; Record "Python" "Installed" }
    else { Bad "Could not install"; Record "Python" "Failed" }
} else {
    Record "Python" "Failed" "winget missing"
}

# ---------- 2. Node.js ----------
Say "Node.js (need v$MinNode or newer)"
$NodeMajor = 0
if (Has "node") { try { $NodeMajor = [int]((& node -v) -replace '^v','' -split '\.')[0] } catch {} }
if ($NodeMajor -ge $MinNode) {
    Ok "Node.js v$NodeMajor already installed"
    Record "Node.js" "AlreadyInstalled"
} elseif ($CheckOnly) {
    Bad "Missing or too old"
    Record "Node.js" "Missing" "need v$MinNode+"
} elseif ($HasWinget) {
    Warn "Installing..."
    Winget-Install "OpenJS.NodeJS.LTS"
    if (Has "node") { Ok "Installed"; Record "Node.js" "Installed" }
    else { Bad "Could not install"; Record "Node.js" "Failed" }
} else {
    Record "Node.js" "Failed" "winget missing"
}

# ---------- 3-4. Git and GitHub CLI ----------
Install-Tool "Git"        "git" { if ($HasWinget) { Winget-Install "Git.Git" } }
Install-Tool "GitHub CLI" "gh"  { if ($HasWinget) { Winget-Install "GitHub.cli" } }

# ---------- 5. Supabase CLI (downloaded from Supabase's official releases) ----------
Install-Tool "Supabase CLI" "supabase" {
    $arch = "amd64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $arch = "arm64" }
    $dir = Join-Path $env:LOCALAPPDATA "Programs\supabase"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tgz = Join-Path $env:TEMP "supabase.tar.gz"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/supabase/cli/releases/latest/download/supabase_windows_$arch.tar.gz" -OutFile $tgz
    tar -xzf $tgz -C $dir
    Remove-Item $tgz -Force -ErrorAction SilentlyContinue
    Add-UserPath $dir
}

# ---------- 6. Vercel CLI ----------
Install-Tool "Vercel CLI" "vercel" {
    if (Has "npm") { npm install -g vercel | Out-Host }
    else { Bad "Needs Node.js, which isn't working" }
}

# ---------- 7. Claude Code ----------
Install-Tool "Claude Code" "claude" {
    try { Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression } catch { Bad "Main install method failed" }
    Add-UserPath "$env:USERPROFILE\.local\bin"
    if (-not (Has "claude") -and (Has "npm")) {
        Warn "Trying the backup install method..."
        npm install -g @anthropic-ai/claude-code | Out-Host
    }
}

# ---------- Git name and email (just a reminder) ----------
$GitNameSet = $false
if (Has "git") {
    $gn = git config --global user.name 2>$null
    $ge = git config --global user.email 2>$null
    if ($gn -and $ge) { $GitNameSet = $true }
}

# ---------- Results table ----------
$Cmds = @{ "Python"="python"; "Node.js"="node"; "Git"="git"; "GitHub CLI"="gh";
           "Supabase CLI"="supabase"; "Vercel CLI"="vercel"; "Claude Code"="claude" }

Write-Host ""
Write-Host "=============================================" -ForegroundColor White
Write-Host "   RESULTS" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
Write-Host ("  {0,-14} {1,-18} {2,-10}" -f "Tool", "Status", "Version")
Write-Host ("  {0,-14} {1,-18} {2,-10}" -f "--------------", "----------------", "--------")
$Failed = 0; $Missing = 0
foreach ($r in $Results) {
    $ver = Get-Ver $Cmds[$r.Name]
    if (-not $ver) { $ver = "-" }
    switch ($r.Status) {
        "Installed"        { $color = "Green" }
        "AlreadyInstalled" { $color = "Green" }
        "Missing"          { $color = "Yellow"; $Missing++ }
        default            { $color = "Red";    $Failed++ }
    }
    Write-Host ("  {0,-14} " -f $r.Name) -NoNewline
    Write-Host ("{0,-18} " -f $r.Status) -ForegroundColor $color -NoNewline
    Write-Host ("{0,-10} {1}" -f $ver, $r.Note) -ForegroundColor DarkGray
}

$Elapsed = (Get-Date) - $Start
Write-Host ""
if ($CheckOnly) {
    if ($Missing -eq 0) { Write-Host "Everything is already installed." -ForegroundColor Green }
    else { Write-Host "$Missing tool(s) missing. Double-click run-setup.bat to install them." -ForegroundColor Yellow }
} elseif ($Failed -eq 0) {
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "   ALL GREEN - setup complete!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Last step - sign in to your tools:" -ForegroundColor White
    Write-Host "  1. Close this window."
    Write-Host "  2. Press Windows Key + R, type powershell, press Enter."
    Write-Host "  3. Run these one at a time, waiting for each to finish:"
    Write-Host ""
    Write-Host "     gh auth login"
    Write-Host "     supabase login"
    Write-Host "     vercel login"
    Write-Host '     git config --global user.name "Your Name"'
    Write-Host '     git config --global user.email "your@email.com"'
    if ($GitNameSet) { Write-Host "     (Your git name and email are already set - you can skip the last two.)" -ForegroundColor DarkGray }
} else {
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "   $Failed tool(s) FAILED" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix: close this window and double-click run-setup.bat again."
    Write-Host "It's safe to run as many times as needed."
    Write-Host "Still failing? Send a screenshot of this table to a workshop assistant."
}
Write-Host ""
Write-Host ("Finished in {0} min {1} sec." -f [int][math]::Floor($Elapsed.TotalMinutes), $Elapsed.Seconds) -ForegroundColor DarkGray
Write-Host "Log saved to: $LogFile" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Read-Host "Press Enter to close this window"
