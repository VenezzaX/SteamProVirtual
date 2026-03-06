
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName Microsoft.VisualBasic, System.Windows.Forms


$hwid = (Get-CimInstance Win32_BaseBoard).SerialNumber.Trim()
$key = [Microsoft.VisualBasic.Interaction]::InputBox("Insira sua chave do produto:", "ATIVAR STEAM DESBLOQUEADA", "")

if (-not $key) { exit }

try {

    $url = "https://waedqlfiprmsdkwhjkea.supabase.co/functions/v1/smooth-worker"
    $body = @{ key = $key; hwid = $hwid } | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -UserAgent "Mozilla/5.0"

    if ($auth.status -eq "authorized") {
        
        Write-Host "----------------------------------------------------" -ForegroundColor Cyan
        Write-Host "         SERVICO ATIVADO PERMANENTEMENTE            " -ForegroundColor Green
        Write-Host "----------------------------------------------------" -ForegroundColor Cyan
        Write-Host "(Qualquer erro ative o novamente com a mesma chave)" -ForegroundColor Yellow
        Write-Host ""

        IEX (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1" -UseBasicParsing)

    } else {
        [System.Windows.Forms.MessageBox]::Show("Chave inválida ou já vinculada a outro computador.", "Acesso Negado")
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro de conexão com o servidor. Verifique sua internet.", "Erro")
}
