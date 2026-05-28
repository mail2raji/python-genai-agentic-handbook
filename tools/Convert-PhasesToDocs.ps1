<#
.SYNOPSIS
    Mirror the 7-Phase hands-on curriculum (../PythonGenAI_Learning) into
    docs/PartII_HandsOn/ as renderable MkDocs pages.

.DESCRIPTION
    Every .py file is wrapped in a Markdown page (title + source code block).
    Every .md file is copied with .py links rewritten to .md links.
    Phase 7 capstone_production_agent/ is rendered as one combined page with
    all sub-files (Python / Dockerfile / k8s YAML) in fenced blocks.

    Also emits docs/PartII_HandsOn/_nav.yml — a YAML fragment ready to paste
    into mkdocs.yml under the "Part II — Hands-On Code Lessons" section.

.NOTES
    Idempotent. Safe to re-run after editing source .py files.
#>

[CmdletBinding()]
param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\..\PythonGenAI_Learning'),
    [string]$DocsRoot   = (Join-Path $PSScriptRoot '..\docs\PartII_HandsOn')
)

$ErrorActionPreference = 'Stop'
$SourceRoot = (Resolve-Path $SourceRoot).Path
$DocsRoot   = (Resolve-Path -LiteralPath (Split-Path $DocsRoot -Parent)).Path
$DocsRoot   = Join-Path $DocsRoot 'PartII_HandsOn'

Write-Host "Source : $SourceRoot" -ForegroundColor Cyan
Write-Host "Target : $DocsRoot"   -ForegroundColor Cyan

if (-not (Test-Path $DocsRoot)) { New-Item -ItemType Directory -Path $DocsRoot -Force | Out-Null }

# ---------- helpers ----------------------------------------------------------

function Format-LessonTitle {
    param([string]$Basename)
    $ti = (Get-Culture).TextInfo
    if ($Basename -match '^(\d+)_(.*)$') {
        $num  = $matches[1].TrimStart('0'); if (-not $num) { $num = '0' }
        $rest = $ti.ToTitleCase(($matches[2] -replace '_', ' ').ToLower())
        return "Lesson $num — $rest"
    }
    elseif ($Basename -match '^mini_project_(.+)$') {
        $rest = $ti.ToTitleCase(($matches[1] -replace '_', ' ').ToLower())
        return "Mini-Project — $rest"
    }
    elseif ($Basename -match '^capstone(\d*)_(.+)$') {
        $n    = $matches[1]
        $rest = $ti.ToTitleCase(($matches[2] -replace '_', ' ').ToLower())
        if ($n) { return "Capstone $n — $rest" } else { return "Capstone — $rest" }
    }
    elseif ($Basename -eq 'llm_client') {
        return 'Shared LLM Client'
    }
    elseif ($Basename -eq '00_START_HERE') {
        return 'Phase overview'
    }
    else {
        return $ti.ToTitleCase(($Basename -replace '_', ' ').ToLower())
    }
}

# Friendly label overrides for known basenames (cosmetic only)
$Script:LabelOverrides = @{
    '01_what_is_llm'             = '1. What is an LLM?'
    '02_first_llm_call'          = '2. Your first LLM call'
    '04_structured_outputs'      = '4. Structured outputs (JSON)'
    '06_apis_requests'           = '6. APIs with requests'
    '07_async'                   = '7. Async I/O'
    '08_env_secrets'             = '8. Env & secrets'
    '07_rag_system'              = '7. RAG system from scratch'
    'mini_project_doc_qa'        = '🛠️ Mini-Project — Doc Q&A'
    'mini_project_csv_analyst'   = '🛠️ Mini-Project — CSV analyst'
    'mini_project_it_triage_agent' = '🛠️ Mini-Project — IT triage agent'
    '01_what_is_agent'           = '1. What is an Agent?'
    '07_langgraph_intro'         = '7. LangGraph intro'
    '01_mcp'                     = '1. MCP — Model Context Protocol'
    '02_mcp_server_and_client'   = '2. MCP server + client'
    '03_memory_production'       = '3. Production memory (Redis + Vector)'
    '04_evaluation'              = '4. Evaluating agents'
    '05_observability'           = '5. Observability — logs, traces, metrics'
    '06_failure_modes'           = '6. Failure modes & defenses'
    '07_architecture'            = '7. Production architecture'
    '08_deploy_langgraph_k8s'    = '8. Deploy LangGraph on Kubernetes'
    '02_venv_and_pip'            = '2. venv & pip'
    'capstone1_spn_renewal_concierge' = '🏆 Capstone 1 — SPN renewal concierge'
    'capstone2_powershell_doc_buddy'  = '🏆 Capstone 2 — PowerShell doc buddy'
    'capstone3_incident_reporter'     = '🏆 Capstone 3 — Incident reporter'
}

function Format-NavLabel {
    param([string]$Basename)
    if ($Script:LabelOverrides.ContainsKey($Basename)) { return $Script:LabelOverrides[$Basename] }
    $ti = (Get-Culture).TextInfo
    if ($Basename -eq '00_START_HERE') { return '0. Overview' }
    if ($Basename -match '^(\d+)_(.*)$') {
        $num  = [int]$matches[1]
        $rest = $ti.ToTitleCase(($matches[2] -replace '_', ' ').ToLower())
        return ('{0}. {1}' -f $num, $rest)
    }
    if ($Basename -match '^mini_project_(.+)$') {
        $rest = $ti.ToTitleCase(($matches[1] -replace '_', ' ').ToLower())
        return ('🛠️ Mini-Project — {0}' -f $rest)
    }
    if ($Basename -match '^capstone(\d*)_(.+)$') {
        $n    = $matches[1]
        $rest = $ti.ToTitleCase(($matches[2] -replace '_', ' ').ToLower())
        if ($n) { return ('🏆 Capstone {0} — {1}' -f $n, $rest) }
        return ('🏆 Capstone — {0}' -f $rest)
    }
    if ($Basename -eq 'llm_client') { return '🧰 Shared LLM Client' }
    return $ti.ToTitleCase(($Basename -replace '_', ' ').ToLower())
}

function Convert-PyToMd {
    param([string]$PyPath, [string]$MdPath, [string]$PhaseLabel)
    $base    = [IO.Path]::GetFileNameWithoutExtension($PyPath)
    $title   = Format-LessonTitle $base
    $code    = Get-Content -LiteralPath $PyPath -Raw -Encoding UTF8
    $relSrc  = (Resolve-Path -LiteralPath $PyPath).Path.Replace($SourceRoot + [IO.Path]::DirectorySeparatorChar, '').Replace('\','/')
    $md = @"
# $title

!!! info "Runnable source file"
    **Path:** ``$relSrc``  
    **Phase:** $PhaseLabel  
    Copy this into a ``.py`` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

``````python
$code
``````
"@
    Set-Content -LiteralPath $MdPath -Value $md -Encoding UTF8
}

function Copy-MdRewriteLinks {
    param([string]$SrcMd, [string]$DstMd)
    $c = Get-Content -LiteralPath $SrcMd -Raw -Encoding UTF8
    # rewrite local relative links ending in .py → .md (but leave URLs alone)
    $c = [regex]::Replace($c, '\(([^)\s]+?)\.py\)', '($1.md)')
    # capstone_production_agent/README.md (mdBook style) → the consolidated capstone page
    $c = [regex]::Replace($c, '\(([^)\s]*?capstone_production_agent)/README\.md\)', '($1.md)')
    # mdBook-only files that don't exist as MkDocs pages → point back to Part II hub
    $c = $c -replace '\(HANDBOOK\.md\)', '(index.md)'
    $c = $c -replace '\(SUMMARY\.md\)', '(index.md)'
    $c = $c -replace '\(README\.md\)', '(index.md)'
    # project assets that aren't part of the rendered book → link to source repo
    $repoRaw = 'https://github.com/mail2raji/python-genai-agentic-handbook/blob/main/PythonGenAI_Learning'
    $c = $c -replace '\(requirements\.txt\)', "($repoRaw/requirements.txt)"
    $c = $c -replace '\(\.env\.example\)', "($repoRaw/.env.example)"
    Set-Content -LiteralPath $DstMd -Value $c -Encoding UTF8
}

# ---------- the 7 phases -----------------------------------------------------

$phases = [ordered]@{
    'Phase1_Python_Fundamentals' = 'Phase 1 — Python Fundamentals'
    'Phase2_Intermediate_Python' = 'Phase 2 — Intermediate Python'
    'Phase3_Python_for_AI'       = 'Phase 3 — Python for AI & Data'
    'Phase4_GenAI_Fundamentals'  = 'Phase 4 — GenAI Fundamentals'
    'Phase5_Agentic_AI'          = 'Phase 5 — Agentic AI'
    'Phase6_Capstone_Projects'   = 'Phase 6 — Capstone Projects'
    'Phase7_Production_Agents'   = 'Phase 7 — Production Agents'
}

# nav fragment builder
$navLines = [System.Collections.Generic.List[string]]::new()
$navLines.Add('  - "Part II — Hands-On Code Lessons":')
$navLines.Add('      - "Part II overview": PartII_HandsOn/index.md')
$navLines.Add('      - "🧪 Lab menu":      PartII_HandsOn/LAB_MENU.md')
$navLines.Add('      - "⚙️ Quickstart":    PartII_HandsOn/QUICKSTART.md')

# preferred ordering inside each phase
function Get-PhaseOrderKey {
    param([string]$Name)
    if ($Name -eq '00_START_HERE')              { return '00' }
    if ($Name -match '^(\d+)_')                 { return $matches[1] }
    if ($Name -match '^capstone(\d+)_')         { return '90_' + $matches[1] }
    if ($Name -eq 'capstone_production_agent')  { return '95' }
    if ($Name -eq 'mini_project')               { return '98' }
    if ($Name -match '^mini_project')           { return '98' }
    if ($Name -eq 'llm_client')                 { return '99' }
    return '50_' + $Name
}

foreach ($phaseKey in $phases.Keys) {
    $phaseLabel = $phases[$phaseKey]
    $srcPhase = Join-Path $SourceRoot $phaseKey
    $dstPhase = Join-Path $DocsRoot $phaseKey
    if (-not (Test-Path $srcPhase)) { Write-Warning "Missing source phase: $srcPhase"; continue }
    if (-not (Test-Path $dstPhase)) { New-Item -ItemType Directory -Path $dstPhase -Force | Out-Null }

    Write-Host "→ $phaseLabel" -ForegroundColor Yellow
    $navLines.Add(('      - "{0}":' -f $phaseLabel))

    $entries = @()

    # files directly in the phase
    Get-ChildItem -LiteralPath $srcPhase -File | Sort-Object Name | ForEach-Object {
        $base = [IO.Path]::GetFileNameWithoutExtension($_.Name)
        $ext  = $_.Extension.ToLower()
        if ($ext -eq '.py') {
            $dst = Join-Path $dstPhase ($base + '.md')
            Convert-PyToMd -PyPath $_.FullName -MdPath $dst -PhaseLabel $phaseLabel
            $entries += [pscustomobject]@{ Sort = (Get-PhaseOrderKey $base); Label = (Format-NavLabel $base); Path = "PartII_HandsOn/$phaseKey/$base.md" }
        }
        elseif ($ext -eq '.md') {
            $dst = Join-Path $dstPhase $_.Name
            Copy-MdRewriteLinks -SrcMd $_.FullName -DstMd $dst
            $entries += [pscustomobject]@{ Sort = (Get-PhaseOrderKey $base); Label = (Format-NavLabel $base); Path = "PartII_HandsOn/$phaseKey/$($_.Name)" }
        }
    }

    # Phase 7 special: capstone_production_agent/ subfolder → one combined page
    $capDir = Join-Path $srcPhase 'capstone_production_agent'
    if (Test-Path $capDir) {
        $dstCapMd = Join-Path $dstPhase 'capstone_production_agent.md'
        $sb = [System.Text.StringBuilder]::new()
        $null = $sb.AppendLine('# 🏆 Final Capstone — Production SPN Agent')
        $null = $sb.AppendLine('')
        $null = $sb.AppendLine('!!! tip "All-in-one capstone"')
        $null = $sb.AppendLine('    A FastAPI agent with Redis memory, OpenTelemetry traces, evals, Dockerfile, docker-compose, and a Kubernetes manifest. The full source tree of every file in `Phase7_Production_Agents/capstone_production_agent/` is embedded below — copy into a folder of the same name and run.')
        $null = $sb.AppendLine('')
        Get-ChildItem -LiteralPath $capDir -Recurse -File | Sort-Object FullName | ForEach-Object {
            $rel = $_.FullName.Substring($capDir.Length).TrimStart('\','/').Replace('\','/')
            $null = $sb.AppendLine("## ``$rel``")
            $null = $sb.AppendLine('')
            $lang = switch -regex ($_.Extension.ToLower()) {
                '\.py$'        { 'python';     break }
                '\.ya?ml$'     { 'yaml';       break }
                '\.md$'        { 'markdown';   break }
                '\.txt$'       { 'text';       break }
                '\.dockerfile$' { 'dockerfile'; break }
                default        { '' }
            }
            if ($_.Name -eq 'Dockerfile') { $lang = 'dockerfile' }
            if ($_.Name -eq 'requirements.txt') { $lang = 'text' }
            $null = $sb.AppendLine('``````' + $lang)
            $null = $sb.AppendLine((Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8))
            $null = $sb.AppendLine('``````')
            $null = $sb.AppendLine('')
        }
        Set-Content -LiteralPath $dstCapMd -Value $sb.ToString() -Encoding UTF8
        $entries += [pscustomobject]@{ Sort = '95'; Label = '🏆 Final Capstone — Production SPN Agent'; Path = "PartII_HandsOn/$phaseKey/capstone_production_agent.md" }
    }

    # emit nav entries for this phase, sorted
    $entries | Sort-Object Sort, Label | ForEach-Object {
        $navLines.Add(('          - "{0}": {1}' -f $_.Label, $_.Path))
    }
}

# ---------- root-level supporting docs ---------------------------------------

# Convert HANDBOOK.md → docs/PartII_HandsOn/index.md (with .py→.md link rewrites and path prefix unchanged)
$handbook = Join-Path $SourceRoot 'HANDBOOK.md'
if (Test-Path $handbook) {
    Copy-MdRewriteLinks -SrcMd $handbook -DstMd (Join-Path $DocsRoot 'index.md')
}

foreach ($file in 'LAB_MENU.md','QUICKSTART.md','CONTRIBUTING.md') {
    $p = Join-Path $SourceRoot $file
    if (Test-Path $p) {
        Copy-MdRewriteLinks -SrcMd $p -DstMd (Join-Path $DocsRoot $file)
    }
}

# write the nav fragment (outside docs/ so MkDocs doesn't ship it)
$navFile = Join-Path $PSScriptRoot '_nav_PartII.yml'
$navLines | Set-Content -LiteralPath $navFile -Encoding UTF8

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Nav fragment written to: $navFile" -ForegroundColor Green
Write-Host "Total entries: $($navLines.Count)" -ForegroundColor Green
