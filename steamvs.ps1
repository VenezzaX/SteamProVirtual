$hwid = (Get-CimInstance Win32_BaseBoard).SerialNumber.Trim()
$keyword = Read-Host "Qual a sua chave do produto"

$url = "https://waedqlfiprmsdkwhjkea.supabase.co/functions/v1/smooth-worker"
$body = @{ key = $keyword; hwid = $hwid } | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    
    if ($response.status -eq "authorized") {
        Write-Host "Acesso Permitido! Ativando..." -ForegroundColor Green
        iwr -useb "https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1" | iex
    }
} catch {
    # This catch block will capture the 403 Forbidden and the 401 Invalid
    Write-Host "Acesso Negado: Chave invalida ou ja vinculada a outro computador." -ForegroundColor Red
}
