# kraken-bootstrap

Petit job de données (stations de vélos en libre-service → taux de remplissage → Parquet) utilisé comme fil rouge des TP ; il servira aussi de premier job à déployer avec Kraken, le projet du module.

## Ce que fait le job

- Lit `data/stations.csv` (extrait simplifié, format défini pour le cours — pas le jeu de données officiel) ou la source indiquée par `SOURCE_URL`.
- Calcule `fill_rate` (taux de remplissage) et `status` (`ok`, `empty` ou `full`).
- Supprime les stations sans capacité (0 vélo et 0 borne libre).
- Écrit le résultat dans `OUTPUT_DIR/stations.parquet`.

## Démarrer

1. Clique sur **Use this template** pour créer ton propre dépôt.
2. Clone-le sur ta machine.
3. Installe `just` (sur macOS : `brew install just`).
4. Vérifie ton poste avec `make doctor`, puis installe les dépendances avec `make install`.
5. Vérifie le code et lance le programme : `make ci run`.

## Commandes du Lab 2

Chaque dépôt de job fournit son propre `justfile` à la racine, avec les mêmes noms de recettes pour que la CI sache quoi appeler :

- `just install` : installer les dépendances ; ici, dans `.venv`.
- `just lint` : vérifier le code ; ici, avec Ruff.
- `just test` : lancer les tests ; pour ce job Python, produire `reports/junit.xml`, y compris quand un test échoue.
- `just ci` : raccourci local pour lancer le lint puis les tests, en s'arrêtant si une étape échoue.

Une recette réussie renvoie le code de sortie `0` ; un échec renvoie un code non nul, ce qui fait échouer l'étape GitHub Actions. Le rapport JUnit permet de lire le détail des tests.

Depuis `kraken-bootstrap`, tu peux utiliser `make install`, `make lint`, `make test` ou `make ci` : ces commandes appellent directement le `justfile` du dépôt. Pour le Lab 2, utilise Python 3.12 : `make install PYTHON=python3.12` si ce n'est pas ton `python3` par défaut.

Le Makefile reste pratique pour la démo :

- `make ci` : lancer Ruff et les tests, avec un rapport dans `reports/junit.xml`.
- `make ci-report` : lire le résumé du dernier rapport local.
- `make ci-runs` : voir les dernières exécutions sur GitHub, une fois les workflows publiés.
- `make ci-logs RUN_ID=123456` : lire les logs d'une exécution, avec son identifiant donné par `make ci-runs`.

Dans GitHub Actions, `kraken-bootstrap/.github/workflows/ci.yml` appelle le workflow complet de `kraken`. Celui-ci enchaîne les jobs `lint-test` et `build-push` : il récupère le dépôt appelant et utilise ses recettes `just install`, `just lint` et `just test` dans des étapes séparées, pour voir où ça échoue. Chaque dépôt peut donc adapter ses commandes tout en gardant les mêmes noms pour la CI. Les commandes de démo ci-dessus ne font ni commit, ni push, ni publication d'image.

## Variables d'environnement

| Variable     | Défaut              | Rôle                          |
|--------------|---------------------|-------------------------------|
| `SOURCE_URL` | `data/stations.csv` | Fichier CSV (ou URL) d'entrée |
| `OUTPUT_DIR` | `output`            | Dossier de sortie du Parquet  |

## Format attendu du CSV

Colonnes obligatoires :

- `station_id`
- `name`
- `bikes_available`
- `docks_available`
- `lat`
- `lon`
- `updated_at`

## Dépannage

Chaque entrée correspond à un contrôle de `make doctor`.

- **Docker : permission refusée (Linux)** : `sudo usermod -aG docker $USER`, puis déconnecte-toi et reconnecte-toi.
- **Docker introuvable ou daemon arrêté (macOS/Windows)** : installe et lance Docker Desktop.
- **`gh` non authentifié** : `gh auth login`
- **`git user.name` non configuré** :
  ```bash
  git config --global user.name "Ton Nom"
  git config --global user.email "toi@exemple.fr"
  ```
- **`make install` échoue** : `make doctor` exige Python ≥ 3.11 et les dépendances épinglées supportent Python 3.11 à 3.14. Vérifie `python3 --version`, ou utilise une version précise : `make install PYTHON=python3.12`.
