# MODO DEBUG ATIVO (Janela não é ocultada)

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
        
        [System.Windows.Forms.MessageBox]::Show("MODO DEBUG ATIVO.`nUma janela preta do PowerShell ficará aberta.", "Aviso de Debug")

        # Usando @' (aspas simples) o PowerShell obedece o texto cegamente
        $bgTask = @'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        try {
            Write-Host "----------------------------------------" -ForegroundColor Yellow
            Write-Host "INICIANDO DEBUG DA INSTALAÇÃO" -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor Yellow
            
            Write-Host "Baixando script original do GitHub..." -ForegroundColor Cyan
            $s = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            Write-Host "Aplicando injeções de memória (Bypass Absoluto)..." -ForegroundColor Cyan
            
            # 1. Troca a pausa do Steamtools por um timer automático de 2 segundos
            $s = $s.Replace('[void][System.Console]::ReadKey($true)', 'Start-Sleep -Seconds 2')
            
            # 2. Destrói o loop de contagem do Millenium (Muda de $i = $milleniumTimer para $i = -1)
            # Como a condição é imediatamente falsa, ele pula a espera 100% das vezes e instala direto.
            $s = $s.Replace('for ($i = $milleniumTimer; $i -ge 0; $i--)', 'for ($i = -1; $i -ge 0; $i--)')
            
            # 3. Garante que qualquer outra checagem de tecla seja ignorada
            $s = $s.Replace('[Console]::KeyAvailable', '$false')

            Write-Host "Executando script na memória..." -ForegroundColor Green
            Invoke-Expression $s

            Write-Host "Baixando aviso final..." -ForegroundColor Cyan
            $wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            $path = "$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile($wUrl, $path)
            Start-Process notepad.exe $path
            
        } catch {
            Write-Host "ERRO FATAL: $_" -ForegroundColor Red
        } finally {
            Write-Host "`n----------------------------------------" -ForegroundColor Yellow
            Write-Host "FIM DA EXECUÇÃO." -ForegroundColor Yellow
            Write-Host "Pressione qualquer tecla para fechar esta janela..." -ForegroundColor White
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
'@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # MUDANÇA: Substituído '-WindowStyle Hidden' por '-WindowStyle Normal'
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Normal", "-EncodedCommand", $encoded
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro de network. Detalhe: $($_.Exception.Message)", "Erro")
}
