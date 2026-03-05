$hwid = (Get-CimInstance Win32_BaseBoard).SerialNumber.Trim()
$keyword = Read-Host "Qual a sua chave do produto"

$url = "https://waedqlfiprmsdkwhjkea.supabase.co/functions/v1/smooth-worker"

$body = @{
    key  = $keyword
    hwid = $hwid
} | ConvertTo-Json

try {
    # No headers needed now!
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    
    if ($response.status -eq "authorized") {
        Write-Host "Acesso Permitido!" -ForegroundColor Green
        iwr -useb "https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1" | iex
    } else {
        Write-Host "Acesso Negado: Chave em uso ou invalida." -ForegroundColor Red
    }
} catch {
    Write-Host "Erro na validacao. Verifique sua conexao." -ForegroundColor Red
}
