# Solicitar el nombre del proyecto
Write-Host "Por favor, ingresa el nombre del proyecto en GitHub:" -ForegroundColor Cyan
$projectName = Read-Host "Nombre del proyecto"

# Construir la URL del repositorio
$repoURL = "https://github.com/abatullu/$projectName.git"
$branchName = "master"  # Cambia a 'main' si usas esa convención

# Confirmar la URL generada
Write-Host "La URL generada para el repositorio remoto es: $repoURL" -ForegroundColor Yellow
Write-Host "Presiona Enter para continuar o Ctrl+C para cancelar." -ForegroundColor Cyan
Read-Host

# Comandos Git automatizados
Write-Host "Iniciando el repositorio local..." -ForegroundColor Cyan
git init

Write-Host "Vinculando el repositorio remoto..." -ForegroundColor Cyan
git remote add origin $repoURL

Write-Host "Agregando todos los archivos al área de preparación..." -ForegroundColor Cyan
git add .

Write-Host "Creando el primer commit..." -ForegroundColor Cyan
git commit -m "Initial commit"

Write-Host "Configurando la rama principal como $branchName..." -ForegroundColor Cyan
git branch -M $branchName

Write-Host "Subiendo los archivos al repositorio remoto..." -ForegroundColor Cyan
git push -u origin $branchName

Write-Host "El repositorio se configuró y subió correctamente." -ForegroundColor Green
