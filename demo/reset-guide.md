# Guide — Reset de démo SRE Agent

## Problème
Quand on refait la démo plusieurs fois dans le même environnement, le SRE Agent :
- Garde l'historique des anciens incidents
- Peut revenir automatiquement aux versions précédentes de l'app
- Crée de la confusion entre les runs (anciennes issues GitHub, alertes résolues, etc.)

## ✅ Solution recommandée : Nouveau repo + nouveau RG

### Workflow pour chaque démo

**1. Avant la démo :**
```powershell
# Clone le template (nouveau nom à chaque fois)
gh repo create sre-demo-$(Get-Date -Format 'yyyyMMdd-HHmm') --template lucmasssol/sre-agent-dataops-template --private --clone
cd sre-demo-20260623-1430  # ou le nom généré

# Deploy l'infrastructure
.\demo\deploy-demo.ps1 -DemoName "demo-20260623-1430"

# Configurer le SRE Agent
# Dans l'interface SRE: ajouter rg-sre-demo-20260623-1430 + repo sre-demo-20260623-1430
```

**2. Pendant la démo :**
- Suivre narrative.md normalement
- L'environnement est propre, aucun historique

**3. Après la démo :**
```powershell
# Supprimer le resource group
az group delete --name rg-sre-demo-20260623-1430 --yes --no-wait

# Archiver ou supprimer le repo
gh repo archive sre-demo-20260623-1430
# ou
gh repo delete sre-demo-20260623-1430 --yes
```

**Avantages :**
- ✅ Zéro historique à chaque run
- ✅ Aucune confusion entre démos
- ✅ Setup en 2 min chrono
- ✅ Coût minimal (ressources éphémères)

---

## ⚙️ Alternative : Reset dans le même environnement

Si tu veux absolument réutiliser le même RG/repo, voici les étapes (plus long et risqué) :

### 1. Fermer tous les anciens incidents GitHub
```powershell
# Lister les issues ouvertes
gh issue list --repo lucmasssol/sre-agent-dataops-demo

# Fermer chaque issue manuellement ou en masse
gh issue close <ISSUE_NUMBER> --repo lucmasssol/sre-agent-dataops-demo --comment "Demo reset"
```

### 2. Résoudre les alertes Azure Monitor
```powershell
# Pas de commande CLI directe pour forcer la résolution
# → Attendre que les alertes passent naturellement en "Resolved" (peut prendre 5-10 min)
# ou modifier les alertes pour augmenter le threshold temporairement
```

### 3. Nettoyer les anciennes releases GitHub
```powershell
# Lister les releases
gh release list --repo lucmasssol/sre-agent-dataops-demo

# Supprimer les releases "broken"
gh release delete v1.0.1-broken --repo lucmasssol/sre-agent-dataops-demo --yes
```

### 4. Redéployer la version saine
```powershell
cd src\function_http
Compress-Archive -Path .\* -DestinationPath ..\..\function-clean.zip -Force
cd ..\..

# Créer une nouvelle release "baseline"
gh release create v1.0.0-clean .\function-clean.zip --title "Baseline clean" --notes "Reset for new demo" --repo lucmasssol/sre-agent-dataops-demo

# Mettre à jour la Function App
$url = "https://github.com/lucmasssol/sre-agent-dataops-demo/releases/download/v1.0.0-clean/function-clean.zip"
az functionapp config appsettings set --name sre-dataops-demo-func --resource-group rg-sre-agent-dataops-demo --settings "WEBSITE_RUN_FROM_PACKAGE=$url"
az functionapp restart --name sre-dataops-demo-func --resource-group rg-sre-agent-dataops-demo
```

### 5. Tester que l'état sain est rétabli
```powershell
# Test avec petit batch
Invoke-RestMethod -Uri "https://sre-dataops-demo-func.azurewebsites.net/api/pipeline/run?code=<FUNCTION_KEY>" -Method Post -ContentType "application/json" -Body '{"batch_id":"test-reset","rows":1000,"source":"manual"}'
# Doit retourner: status: ok, processed_rows: 1000

# Test avec gros batch
Invoke-RestMethod -Uri "https://sre-dataops-demo-func.azurewebsites.net/api/pipeline/run?code=<FUNCTION_KEY>" -Method Post -ContentType "application/json" -Body '{"batch_id":"test-reset-large","rows":200000,"source":"manual"}'
# Doit aussi retourner: status: ok, processed_rows: 200000 (sans erreur)
```

### 6. Réinitialiser l'historique SRE Agent
⚠️ **Problème :** Il n'existe pas de commande pour effacer l'historique du SRE Agent.
- Le SRE Agent garde en mémoire les incidents, correlations, fixes précédents
- Seule solution : contacter l'équipe SRE Agent pour reset ou attendre que la mémoire expire

**C'est pour ça qu'on recommande l'approche nouveau RG/repo.**

---

## 🎯 Récap : Pourquoi nouveau RG + repo ?

| Critère | Nouveau RG/repo | Reset même env |
|---------|----------------|----------------|
| Temps setup | **2 min** (script) | 10-15 min (manuel) |
| Historique propre | ✅ Garanti | ⚠️ Partiel |
| SRE Agent confusion | ✅ Aucune | ❌ Possible |
| Coût | Minimal (delete après) | Même coût |
| Risque d'erreur | ✅ Faible | ⚠️ Moyen |
| Reproductibilité | ✅ Parfaite | ⚠️ Variable |

**Verdict :** Nouveau RG/repo à chaque démo = meilleure expérience.

---

## 📌 Commandes rapides

### Setup nouvelle démo (2 min)
```powershell
gh repo create sre-demo-$(Get-Date -Format 'yyyyMMdd-HHmm') --template lucmasssol/sre-agent-dataops-template --private --clone
cd sre-demo-*
.\demo\deploy-demo.ps1 -DemoName "demo-$(Get-Date -Format 'yyyyMMdd-HHmm')"
```

### Cleanup après démo (30s)
```powershell
az group delete --name rg-sre-demo-* --yes --no-wait
gh repo archive sre-demo-*
```

Voilà ! Démo propre à chaque fois, zéro friction. 🎯
