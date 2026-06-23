# Azure SRE Agent Demo — Template Réutilisable

> **Template pour démos reproductibles** : Déployez une nouvelle démo SRE Agent propre en 2 minutes chrono.

## 🎯 Objectif

Ce repo template permet de créer des démos Azure SRE Agent répétables avec :
- Environnement Azure propre à chaque fois (nouveau RG + ressources)
- Historique clean (pas de confusion avec anciennes démos)
- Déploiement ultra rapide (script automatisé)
- Nettoyage facile (delete RG après démo)

## 🚀 Quick Start

### 1. Utiliser ce template pour une nouvelle démo

```powershell
# Option A: Clone via GitHub (recommandé)
gh repo create sre-demo-20260623 --template lucmasssol/sre-agent-dataops-template --private --clone
cd sre-demo-20260623

# Option B: Clone manuel
git clone https://github.com/lucmasssol/sre-agent-dataops-template sre-demo-20260623
cd sre-demo-20260623
git remote set-url origin https://github.com/lucmasssol/sre-demo-20260623.git
```

### 2. Déployer l'infrastructure Azure

```powershell
.\demo\deploy-demo.ps1 -DemoName "demo-20260623"
```

Le script crée automatiquement :
- Resource Group : `rg-sre-demo-20260623`
- Function App : `func-sre-demo-20260623`
- App Insights : `insights-sre-demo-20260623`
- Log Analytics : `laws-sre-demo-20260623`
- Alertes Azure Monitor configurées
- Code sain déployé et testé

### 3. Configurer le SRE Agent

Dans l'interface SRE Agent :
- Ajouter le resource group : `rg-sre-demo-20260623`
- Ajouter le repo GitHub : `lucmasssol/sre-demo-20260623`

### 4. Faire la démo

Suivre le narrative complet dans [`demo/narrative.md`](demo/narrative.md) :
1. Montrer état sain
2. Introduire bug avec Copilot (voir `demo/broken-code-snippet.py`)
3. Déclencher incident
4. SRE Agent détecte et crée issue GitHub
5. Copilot propose fix
6. Merger et redéployer
7. Vérifier recovery

### 5. Nettoyer après la démo

```powershell
az group delete --name rg-sre-demo-20260623 --yes --no-wait
gh repo archive sre-demo-20260623  # ou delete
```

---

## 📁 Structure du template

```
sre-agent-dataops-template/
├── src/function_http/          # Code Azure Function (sain)
│   ├── process_batch/
│   │   ├── __init__.py         # Traitement batch
│   │   └── function.json       # HTTP trigger
│   ├── host.json
│   └── requirements.txt
├── infra/
│   └── main.bicep              # Infrastructure as Code
├── logic-app/
│   └── workflow.json           # Logic App (optionnel)
├── demo/
│   ├── deploy-demo.ps1         # 🔧 Script de déploiement rapide
│   ├── narrative.md            # 📖 Guide étape par étape
│   └── broken-code-snippet.py  # 🐛 Bug à introduire pendant la démo
├── .github/workflows/
│   └── deploy.yml              # CI/CD (optionnel)
└── README.md                   # Ce fichier
```

---

## 🎬 Démo narrative résumé

1. **Contexte** : Pipeline Data Ops avec Logic App → Function → App Insights
2. **Sain** : Petit batch (1000 rows) → `status: ok`
3. **Bug** : Copilot ajoute condition qui fail sur gros volumes
4. **Incident** : Gros batch (200k rows) → HTTP 500, exceptions
5. **Détection** : Azure Monitor → Alertes Fired → SRE Agent crée issue GitHub
6. **Fix** : Copilot analyse issue → propose PR → merge
7. **Recovery** : Redéploiement → gros batch OK à nouveau

**Durée totale** : ~10 minutes

---

## 🔧 Personnalisation

### Modifier le code de la Function

Éditer `src/function_http/process_batch/__init__.py` pour ton use case.

### Modifier l'infrastructure

Éditer `infra/main.bicep` pour ajouter/retirer des ressources.

### Changer le scenario de bug

Éditer `demo/broken-code-snippet.py` avec ton propre bug métier.

---

## 💡 Avantages de cette approche

✅ **Historique clean** : chaque démo part de zéro  
✅ **Rapide** : 2 min de setup automatisé  
✅ **Reproductible** : même démo N fois sans confusion  
✅ **Pas cher** : ressources éphémères, delete après  
✅ **Scalable** : template réutilisable pour toute l'équipe  

---

## 📚 Documentation complète

- **[Narrative de démo](demo/narrative.md)** : script complet étape par étape
- **[Bicep infrastructure](infra/main.bicep)** : ressources Azure déployées
- **[Script de déploiement](demo/deploy-demo.ps1)** : automatisation setup

---

## 🆘 Troubleshooting

### La Function ne démarre pas
- Vérifier les settings App Insights dans le portail
- Attendre 30-60s après `az functionapp restart`
- Vérifier les logs : `az monitor log-analytics query`

### Les alertes ne se déclenchent pas
- Vérifier qu'elles ont des action groups configurés
- Générer au moins 5-10 erreurs sur 5 minutes
- Attendre 2-3 min après les erreurs

### Le SRE Agent ne crée pas d'issue
- Vérifier qu'il surveille bien le bon resource group
- Vérifier qu'il a accès au repo GitHub
- Vérifier les action groups des alertes

---

## 🤝 Contribuer

Pour améliorer ce template :
1. Fork le repo
2. Créer une branche feature
3. Proposer une PR avec améliorations

---

**Maintenu par** : Luc Massol  
**Dernière mise à jour** : Juin 2026

**Dans VS Code avec GitHub Copilot, ouvrir `src/function_http/process_batch/__init__.py` et entrer ce prompt :**

```
Modifie ce code pour gérer les grands volumes : si rows > 50000,
lève une RuntimeError("memory pressure detected on large batch").
```

Copilot va modifier le code. **Commiter et pusher :**

```bash
git add src/function_http/process_batch/__init__.py
git commit -m "perf: add memory pressure guard for large batches"
git push
```

GitHub Actions se déclenche → déploiement automatique via GitHub Release.

Ou déploiement manuel (si CI/CD pas encore configuré) :

```bash
cd src/function_http
# Windows :
Compress-Archive -Path .\* -DestinationPath ..\..\function-http-demo-broken.zip -Force
gh release create v1.0.1-broken ..\..\function-http-demo-broken.zip --title "Broken deployment" --notes "Bug introduced"
# Puis update la function app setting WEBSITE_RUN_FROM_PACKAGE avec la nouvelle URL + restart
```

---

### 🔴 Phase 3 — Déclencher l'incident (1 min)

> *"La Logic App envoie un gros batch — et là, ça explose."*

```bash
curl -X POST "https://sre-dataops-demo-func.azurewebsites.net/api/pipeline/run?code=<FUNCTION_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"batch_id":"demo-large","rows":200000,"source":"logic-app"}'
```

**Réponse attendue :**
```json
{"status": "error", "message": "memory pressure detected on large batch"}
```
HTTP 500.

Rappeler plusieurs fois pour générer un spike dans App Insights.

---

### 🤖 Phase 4 — SRE Agent détecte l'incident (2 min)

> *"L'Azure SRE Agent surveille Application Insights en continu. Il détecte le spike d'erreurs 500 et crée automatiquement un GitHub issue."*

Dans GitHub → Issues : un issue apparaît automatiquement, par exemple :
```
🔴 [Incident] process_batch: spike in HTTP 500 errors detected
Severity: High | Service: sre-dataops-demo-func | Errors: 12 in 5 min
App Insights query: ...
```

Montrer l'issue créé par le SRE Agent avec le diagnostic.

---

### 🛠️ Phase 5 — Fix avec GitHub Copilot (2 min)

> *"Copilot Coding Agent analyse l'issue et propose un fix..."*

**Option A — Copilot Coding Agent sur l'issue :**
Assigner l'issue au Copilot agent → il propose un PR avec le fix.

**Option B — Fix manuel avec Copilot en live :**

Ouvrir `src/function_http/process_batch/__init__.py`, prompt :

```
Supprime la contrainte artificielle sur les gros volumes et
garde un logging structuré robuste pour batch_id et rows.
```

Commiter, pusher → déploiement automatique.

---

### ✅ Phase 6 — Recovery (1 min)

> *"Après redéploiement, le pipeline est à nouveau sain."*

```bash
curl -X POST "https://sre-dataops-demo-func.azurewebsites.net/api/pipeline/run?code=<FUNCTION_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"batch_id":"demo-large","rows":200000,"source":"logic-app"}'
```

**Réponse :** `{"status": "ok", ..., "processed_rows": 200000}` ✅

Montrer dans **App Insights → Live Metrics** : zéro exception, toutes les requêtes vertes.

SRE Agent ferme l'incident ou le marque résolu.

---

## Repo structure

```text
.
├── .github/workflows/deploy.yml   ← CI/CD via GitHub Releases
├── infra/main.bicep               ← Infrastructure as Code
├── logic-app/workflow.json        ← Logic App workflow
├── src/function_http/
│   ├── host.json
│   ├── requirements.txt
│   └── process_batch/
│       ├── __init__.py            ← ⭐ Fichier central de la démo
│       └── function.json
└── data/
    ├── payload-small.json         ← {"batch_id":"demo-small","rows":1000}
    └── payload-large.json         ← {"batch_id":"demo-large","rows":200000}
```

## Copilot prompts (copier-coller prêts)

### Introduire le bug
```
Modifie ce code pour gérer les grands volumes : si rows > 50000,
lève une RuntimeError("memory pressure detected on large batch").
```

### Fixer le bug
```
Supprime la contrainte artificielle sur les gros volumes et
garde un logging structuré robuste pour batch_id et rows.
```

## Déploiement manuel (sans CI/CD)

```powershell
# 1. Zipper le code
cd src/function_http
Compress-Archive -Path .\* -DestinationPath ..\..\function-http-demo.zip -Force

# 2. Créer une GitHub Release avec le zip
gh release create v1.0.X ..\..\function-http-demo.zip --title "Deploy vX" --notes "Demo deployment"

# 3. Mettre à jour la Function App (remplacer l'URL par la nouvelle release)
$url = "https://github.com/lucmasssol/sre-agent-dataops-demo/releases/download/v1.0.X/function-http-demo.zip"
az functionapp config appsettings set --name sre-dataops-demo-func --resource-group rg-sre-agent-dataops-demo --settings "WEBSITE_RUN_FROM_PACKAGE=$url"
az functionapp restart --name sre-dataops-demo-func --resource-group rg-sre-agent-dataops-demo
```

