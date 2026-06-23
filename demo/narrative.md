# Narrative de démo Azure SRE Agent — Data Ops Pipeline

## Préparation (avant la démo)
1. Déployer l'environnement : `.\demo\deploy-demo.ps1 -DemoName "demo-presentation"`
2. Noter les noms des ressources (RG, Function, App Insights)
3. Configurer le SRE Agent pour surveiller le resource group
4. Ouvrir les onglets portail :
   - App Insights → Live Metrics
   - App Insights → Failures
   - Azure Monitor → Alerts
   - GitHub → Issues du repo

---

## 🎬 Démo en 10 minutes

### 1️⃣ Contexte (30s)
> "On a un pipeline Data Ops : une Logic App déclenche une Azure Function toutes les 2 minutes pour traiter des batches de données. Tout est surveillé par App Insights et Azure SRE Agent."

### 2️⃣ État sain (1 min)
Montrer App Insights → tout vert, pas d'erreur.

Tester manuellement un petit batch :
```powershell
$key = "<FUNCTION_KEY>"
Invoke-RestMethod -Uri "https://<FUNCTION_NAME>.azurewebsites.net/api/pipeline/run?code=$key" -Method Post -ContentType "application/json" -Body '{"batch_id":"demo-small","rows":1000,"source":"manual"}'
```
✅ Résultat : `status: ok`, `processed_rows: 1000`

### 3️⃣ Introduction du bug (2 min)
> "Un Data Engineer demande à Copilot d'optimiser le code pour gérer les gros volumes..."

Dans VS Code, ouvrir `src/function_http/process_batch/__init__.py` et demander à Copilot :
```
Modifie ce code pour gérer les grands volumes : si rows > 50000,
lève une RuntimeError("memory pressure detected on large batch").
```

Copilot ajoute la condition. **Commiter et déployer :**
```powershell
cd src\function_http
Compress-Archive -Path .\* -DestinationPath ..\..\function-broken.zip -Force
cd ..\..
gh release create v1.0.1-broken .\function-broken.zip --title "Bug: memory pressure guard" --notes "Fails on large batches"

$url = "https://github.com/<REPO>/releases/download/v1.0.1-broken/function-broken.zip"
az functionapp config appsettings set --name <FUNCTION_NAME> --resource-group <RG> --settings "WEBSITE_RUN_FROM_PACKAGE=$url"
az functionapp restart --name <FUNCTION_NAME> --resource-group <RG>
```
Attendre 20-30s.

### 4️⃣ Déclenchement de l'incident (1 min)
Envoyer plusieurs gros batches :
```powershell
1..10 | ForEach-Object {
  Invoke-RestMethod -Uri "https://<FUNCTION_NAME>.azurewebsites.net/api/pipeline/run?code=$key" -Method Post -ContentType "application/json" -Body '{"batch_id":"incident","rows":200000,"source":"logic-app"}' -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
}
```
❌ Résultat : HTTP 500, exceptions dans App Insights

Montrer dans **App Insights → Failures** : spike d'erreurs `RuntimeError`.

### 5️⃣ Détection par Azure Monitor (1 min)
Aller dans **Azure Monitor → Alerts** :
- Alertes `dataops-exception-spike` et `dataops-http500-spike` passent en **Fired** 🔴
> "Le système de monitoring a détecté l'anomalie."

### 6️⃣ SRE Agent crée l'incident (1 min)
Aller dans **GitHub → Issues** du repo :
- Un nouvel issue apparaît automatiquement, créé par le SRE Agent
- Titre : `🔴 [Incident] process_batch: spike in HTTP 500 errors`
- Contenu : diagnostic, sévérité, métrique, query App Insights

> "Le SRE Agent a corrélé les alertes, analysé les logs, et créé cet incident GitHub automatiquement."

### 7️⃣ Fix avec GitHub Copilot (2 min)
Dans l'issue, assigner à Copilot ou demander manuellement :
> "Supprime la contrainte artificielle sur les gros volumes et garde un logging robuste."

Copilot propose une PR avec le fix. **Merger la PR.**

Redéployer :
```powershell
# Même processus qu'avant, avec tag v1.0.2-fixed
```

### 8️⃣ Recovery (1 min)
Retester avec gros batch :
```powershell
Invoke-RestMethod -Uri "https://<FUNCTION_NAME>.azurewebsites.net/api/pipeline/run?code=$key" -Method Post -ContentType "application/json" -Body '{"batch_id":"recovery","rows":200000,"source":"manual"}'
```
✅ Résultat : `status: ok`, `processed_rows: 200000`

Montrer :
- App Insights → Failures : plus d'erreur
- Azure Monitor → Alerts : alertes resolved
- GitHub → Issue : fermé ou marqué résolu

> "Incident détecté, diagnostiqué, corrigé et vérifié — le tout en moins de 10 minutes avec assistance automatisée."

---

## 🗑️ Nettoyage après la démo
```powershell
az group delete --name <RG> --yes --no-wait
```

Le repo peut être archivé ou supprimé.
