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
3. Vérifie ton poste : `make doctor`
4. Installe, teste, lint et lance : `make install test lint run`

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
