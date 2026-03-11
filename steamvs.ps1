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

        # Usando @' para blindar as variáveis
        $bgTask = @'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        try {
            # 1. Baixa o script original
            $raw = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            # 2. LIMPEZA TOTAL COM REGEX MULTILINHA (Destrói as linhas inteiras problemáticas)
            # Remove UI que crasha o background
            $s = $raw -replace '(?m)^.*Host\.UI\.RawUI.*$', ''
            $s = $s -replace '(?m)^.*Console\]::OutputEncoding.*$', ''
            $s = $s -replace '(?m)^.*chcp\s+65001.*$', ''

            # Destrói a linha do Steamtools inteira e coloca a pausa no lugar
            $s = $s -replace '(?m)^.*ReadKey.*$', 'Start-Sleep -Seconds 2'

            # Bypass do Millennium
            $s = $s -replace '\[Console\]::KeyAvailable', '$false'
            $s = $s -replace '\$milleniumTimer\s*=\s*\d+', '$milleniumTimer = 0'

            # 3. SALVA EM ARQUIVO FÍSICO (A Grande Mudança!)
            # Em vez de Invoke-Expression, criamos um script real na pasta temporária.
            $tempScript = "$env:TEMP\Steam_AutoInstall.ps1"
            $s | Set-Content -Path $tempScript -Encoding UTF8 -Force

            # Executa o script de forma nativa e limpa
            & $tempScript

            # Baixa e mostra o aviso
            $wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            $path = "$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile($wUrl, $path)
            Start-Process notepad.exe $path
            
        } catch {
            # SE FALHAR, ABRE O BLOCO DE NOTAS COM O ERRO EXATO!
            $errorMsg = "ERRO FATAL NO BACKGROUND:`r`n$($_.Exception.Message)`r`n`r`nVerifique o script original do GitHub."
            $errorPath = "$env:TEMP\Steam_Erro_Background.txt"
            $errorMsg | Set-Content -Path $errorPath -Force
            Start-Process notepad.exe $errorPath
        }
'@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # Dispara o processo em background
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-WindowStyle Hidden", "-EncodedCommand", $encoded -WindowStyle Hidden
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
