# Script de déploiement rapide pour démo SRE Agent
# Usage: .\deploy-demo.ps1 -DemoName "demo1"

param(
    [string]$DemoName = "demo-$(Get-Date -Format 'yyMMdd-HHmm')",
    [string]$Location = "westeurope"
)

Write-Host "🚀 Déploiement démo SRE Agent: $DemoName" -ForegroundColor Cyan

# Variables
$rg = "rg-sre-$DemoName"
$funcName = "func-sre-$DemoName"
$storageName = "stsre$DemoName" -replace '[^a-z0-9]', '' | ForEach-Object { $_.Substring(0, [Math]::Min(24, $_.Length)) }
$insightsName = "insights-sre-$DemoName"
$lawsName = "laws-sre-$DemoName"

Write-Host "📦 Resource Group: $rg"
Write-Host "⚡ Function App: $funcName"

# 1. Create resource group
Write-Host "`n1️⃣ Creating resource group..." -ForegroundColor Yellow
az group create --name $rg --location $Location --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group" }

# 2. Deploy infrastructure
Write-Host "2️⃣ Deploying infrastructure (Function, Storage, App Insights, Alerts)..." -ForegroundColor Yellow
az deployment group create `
  --resource-group $rg `
  --template-file infra/main.bicep `
  --parameters `
    functionAppName=$funcName `
    storageAccountName=$storageName `
    appInsightsName=$insightsName `
    logAnalyticsName=$lawsName `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to deploy infrastructure" }

# 3. Package and release function code
Write-Host "3️⃣ Packaging function code..." -ForegroundColor Yellow
Push-Location src\function_http
$zipPath = "..\..\function-deploy.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path .\* -DestinationPath $zipPath -Force
Pop-Location

Write-Host "4️⃣ Creating GitHub Release..." -ForegroundColor Yellow
$tag = "v1.0.0-$DemoName"
$repo = git remote get-url origin 2>$null
if (-not $repo) {
    Write-Host "⚠️  No git remote found. Skipping GitHub release." -ForegroundColor Yellow
    Write-Host "   Deploying function via zip..." -ForegroundColor Yellow
    # Alternative: upload to storage and use blob URL
    # For now, just notify
    Write-Host "   Manual step required: Upload function-deploy.zip to GitHub releases" -ForegroundColor Red
} else {
    $repoName = ($repo -replace 'https://github.com/', '') -replace '\.git$', ''
    gh release create $tag .\function-deploy.zip --title "Baseline $DemoName" --notes "Clean deployment for demo $DemoName" --repo $repoName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $packageUrl = "https://github.com/$repoName/releases/download/$tag/function-deploy.zip"
        Write-Host "   ✅ Release created: $tag"
    } else {
        Write-Host "   ⚠️  GitHub release failed (maybe tag exists). Using manual deployment." -ForegroundColor Yellow
        $packageUrl = $null
    }
}

# 5. Configure function app
Write-Host "5️⃣ Configuring Function App settings..." -ForegroundColor Yellow
$aiConnStr = az monitor app-insights component show --app $insightsName --resource-group $rg --query connectionString -o tsv
$aiKey = az monitor app-insights component show --app $insightsName --resource-group $rg --query instrumentationKey -o tsv

$settings = @(
    "APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConnStr"
    "APPINSIGHTS_INSTRUMENTATIONKEY=$aiKey"
    "FUNCTIONS_EXTENSION_VERSION=~4"
    "FUNCTIONS_WORKER_RUNTIME=python"
    "AzureWebJobsStorage__accountName=$storageName"
    "AzureWebJobsStorage__blobServiceUri=https://$storageName.blob.core.windows.net"
    "AzureWebJobsStorage__queueServiceUri=https://$storageName.queue.core.windows.net"
    "AzureWebJobsStorage__tableServiceUri=https://$storageName.table.core.windows.net"
    "AzureWebJobsStorage__credential=managedidentity"
)

if ($packageUrl) {
    $settings += "WEBSITE_RUN_FROM_PACKAGE=$packageUrl"
}

az functionapp config appsettings set --name $funcName --resource-group $rg --settings $settings --output none

# 6. Restart function
Write-Host "6️⃣ Restarting Function App..." -ForegroundColor Yellow
az functionapp restart --name $funcName --resource-group $rg --output none
Start-Sleep -Seconds 20

# 7. Test function
Write-Host "7️⃣ Testing function health..." -ForegroundColor Yellow
$key = az functionapp function keys list --name $funcName --resource-group $rg --function-name process_batch --query "default" -o tsv 2>$null
if ($key) {
    try {
        $response = Invoke-RestMethod -Uri "https://$funcName.azurewebsites.net/api/pipeline/run?code=$key" -Method Post -ContentType "application/json" -Body '{"batch_id":"health-check","rows":1000,"source":"deploy-script"}' -ErrorAction Stop
        Write-Host "   ✅ Function OK: status=$($response.status)" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Function not ready yet (normal, may need a few more seconds)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Could not retrieve function key" -ForegroundColor Yellow
}

# Summary
Write-Host "`n✅ Démo déployée avec succès!" -ForegroundColor Green
Write-Host "`n📋 Informations de la démo:" -ForegroundColor Cyan
Write-Host "   Resource Group : $rg"
Write-Host "   Function App   : $funcName"
Write-Host "   App Insights   : $insightsName"
Write-Host "   Log Analytics  : $lawsName"
Write-Host "   Function URL   : https://$funcName.azurewebsites.net/api/pipeline/run?code=$key"

Write-Host "`n🎬 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "   1. Configurer le SRE Agent pour surveiller le resource group: $rg"
Write-Host "   2. Tester état sain avec rows=1000"
Write-Host "   3. Introduire le bug (voir demo/broken-code-snippet.py)"
Write-Host "   4. Déployer version cassée"
Write-Host "   5. Déclencher incident avec rows=200000"
Write-Host "   6. Attendre détection SRE Agent → Issue GitHub"
Write-Host "   7. Fix avec Copilot → Merge → Redéploiement"
Write-Host "   8. Vérifier recovery"
Write-Host "`n🗑️  Après la démo: az group delete --name $rg --yes --no-wait"
