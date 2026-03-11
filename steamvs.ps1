# Não ocultamos a janela inicial para garantir que não há conflitos de interface

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
        
        [System.Windows.Forms.MessageBox]::Show("STEAM DESBLOQUEADA ATIVADA PERMANENTEMENTE`n(Qualquer erro ative novamente com a mesma chave)`n`nUma janela do console abrirá para acompanhar a instalação.", "Sucesso")

        # Usando @' para passar o comando de forma segura
        $bgTask = @'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Define o caminho do log
        $logPath = "$env:TEMP\SteamAtivador_Log.txt"
        Start-Transcript -Path $logPath -Force
        
        try {
            Write-Host "Baixando script original do GitHub..." -ForegroundColor Cyan
            $rawScript = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            Write-Host "Executando instalação..." -ForegroundColor Green
            # Executa o script original na íntegra.
            # Como a janela está visível, os comandos [Console]::ReadKey e Host.UI funcionarão perfeitamente.
            Invoke-Expression $rawScript

            Write-Host "Baixando aviso final..." -ForegroundColor Cyan
            $wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            $path = "$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile($wUrl, $path)
            Start-Process notepad.exe $path
            
        } catch {
            Write-Host "ERRO FATAL: $_" -ForegroundColor Red
        } finally {
            Stop-Transcript
            Write-Host "`nInstalação concluída. Pressione ENTER para fechar a janela..." -ForegroundColor Yellow
            Read-Host
        }
'@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # Dispara o processo em modo Normal (Visível) para o utilizador poder interagir e ver os logs
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-WindowStyle Normal", "-EncodedCommand", $encoded
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
