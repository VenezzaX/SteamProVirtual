
$keyword = Read-Host "Qual a sua chave do produto"

$validKeywords = @("definitive", "water", "lord", "aqua")

if ($validKeywords -contains $keyword) {
    Write-Host "Senha correta ativando steam..." -ForegroundColor Green
    iwr -useb "https://raw.githubusercontent.com/VenezzaX/SteamFunDependencies/refs/heads/main/steampro.ps1" | iex
} else {
    Write-Host "Senha Incorreta." -ForegroundColor Red
}
