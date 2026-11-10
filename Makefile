PYTHON ?= python3
IMAGE ?= kraken-bootstrap
OUT_DIR ?= out
RUN_ID ?=

.DEFAULT_GOAL := help

.PHONY: help doctor install test lint run ci ci-report ci-runs ci-logs \
	docker-build docker-rebuild docker-run \
	docker-run-volume docker-output docker-info docker-images docker-ps \
	docker-history docker-shell docker-check

help:
	@printf '%s\n' \
		'Commandes locales (sur le Mac) :' \
		'  make doctor          Vérifier les outils et la connexion GitHub' \
		'  make install         Installer les dépendances dans .venv' \
		'  make test            Lancer les tests et créer reports/junit.xml' \
		'  make lint            Vérifier le code avec Ruff' \
		'  make run             Lancer le programme localement : output/stations.parquet' \
		'' \
		'Lab 2 : vérifier et présenter la CI :' \
		'  make ci              Lancer Ruff puis les tests via just, avec un rapport JUnit' \
		'  make ci-report       Lire le résumé du dernier rapport local' \
		'  make ci-runs         Voir les 5 dernières exécutions sur GitHub (lecture seule)' \
		'  make ci-logs RUN_ID=123  Lire les logs GitHub de cette exécution' \
		'  install, lint, test et ci utilisent just : brew install just sur le Mac.' \
		'  Ces commandes utilisent le justfile à la racine de ce dépôt.' \
		'  Les commandes GitHub nécessitent gh connecté et des workflows déjà publiés.' \
		'' \
		'Construire et lancer Docker :' \
		'  make docker-build       Construire avec le cache et afficher les étapes' \
		'  make docker-rebuild     Reconstruire sans le cache des étapes Docker' \
		'  make docker-run         Lancer le job ; résultat temporaire dans le conteneur' \
		'  make docker-run-volume  Lancer le job et conserver/remplacer out/stations.parquet' \
		'  make docker-output      Lire le Parquet du dossier partagé avec Python dans Docker' \
		'  make docker-check       Construire, vérifier UID/taille, exécuter et relire le résultat' \
		'' \
		'Comprendre ce qui se passe :' \
		'  make docker-info     Afficher la commande, la taille, le compte et les dossiers internes' \
		'  make docker-images   Voir les images et leurs tailles' \
		'  make docker-ps       Voir les conteneurs encore présents pour cette image' \
		'  make docker-history  Voir les couches et les commandes de construction' \
		'  make docker-shell    Ouvrir un terminal dans un nouveau conteneur ; exit pour sortir' \
		'' \
		'Image = environnement préparé par build ; conteneur = une exécution de cette image.' \
		'--rm supprime le conteneur après arrêt ; le dossier partagé reste sur le Mac.' \
		'Les commandes docker-run utilisent la dernière image construite : reconstruire après une modification.' \
		'Exemples : make docker-info IMAGE=kraken-bootstrap:naif ; make docker-run-volume OUT_DIR=out-essai' \
		'Aucune de ces commandes ne fait de commit ni de push.'

doctor:
	@./scripts/doctor.sh

install:
	PYTHON="$(PYTHON)" just install

test:
	just test

lint:
	just lint

# Les mêmes commandes de vérification sont utilisées en local et dans la CI.
ci:
	just ci

ci-report:
	@test -f reports/junit.xml || { printf '%s\n' 'Rapport absent : lance make test ou make ci.'; exit 1; }
	@.venv/bin/python -c 'import xml.etree.ElementTree as ET; suites = list(ET.parse("reports/junit.xml").getroot().iter("testsuite")); totals = {key: sum(int(suite.get(key, "0")) for suite in suites) for key in ("tests", "failures", "errors")}; print("Tests : {tests} | Échecs : {failures} | Erreurs : {errors}".format(**totals))'

# Lecture seule : ces commandes ne lancent ni workflow ni publication.
ci-runs:
	gh run list --limit 5

ci-logs:
	@test -n "$(RUN_ID)" || { printf '%s\n' 'Indique un identifiant : make ci-logs RUN_ID=123 (visible avec make ci-runs).'; exit 1; }
	gh run view "$(RUN_ID)" --log

run:
	.venv/bin/python -m app.main

# Construction : les commandes restent affichées pour voir ce que make exécute.
docker-build:
	docker build --progress=plain -t "$(IMAGE)" .

docker-rebuild:
	docker build --no-cache --progress=plain -t "$(IMAGE)" .

# Sans volume, le résultat disparaît avec le conteneur à la fin du job.
docker-run:
	docker run --rm "$(IMAGE)"

# Le chemin avant : est sur le Mac ; /out est le chemin vu par le conteneur.
docker-run-volume:
	mkdir -p "$(OUT_DIR)"
	docker run --rm -e OUTPUT_DIR=/out -v "$$(cd "$(OUT_DIR)" && pwd):/out" "$(IMAGE)"
	ls -lh "$(OUT_DIR)/stations.parquet"

docker-output:
	@test -f "$(OUT_DIR)/stations.parquet" || { printf '%s\n' 'Fichier absent : lance make docker-run-volume avec le même OUT_DIR.'; exit 1; }
	docker run --rm --mount "type=bind,source=$$(cd "$(OUT_DIR)" && pwd),target=/out,readonly" --entrypoint python "$(IMAGE)" -c 'import pandas as pd; df = pd.read_parquet("/out/stations.parquet"); print(f"{len(df)} lignes, {len(df.columns)} colonnes"); print(df.to_string(index=False))'

docker-info:
	docker image inspect --format 'Utilisateur configuré : {{if index .Config "User"}}{{index .Config "User"}}{{else}}root (par défaut){{end}} | Commande : {{json .Config.Cmd}} | Taille : {{.Size}} octets' "$(IMAGE)"
	docker run --rm --entrypoint sh "$(IMAGE)" -c 'id; pwd; ls -ld /app /app/output; ls /app'

docker-images:
	docker image ls "$(IMAGE)"

docker-ps:
	docker ps -a --filter "ancestor=$(IMAGE)"

docker-history:
	docker history "$(IMAGE)"

docker-shell:
	docker run --rm -it --entrypoint sh "$(IMAGE)"

# Les vérifications sont séquentielles, même avec make -j.
docker-check: docker-build
	@uid=$$(docker run --rm --entrypoint id "$(IMAGE)" -u) && \
		if [ "$$uid" -ne 0 ]; then printf 'Utilisateur non-root : UID %s\n' "$$uid"; \
		else printf '%s\n' 'Échec : le conteneur utilise root.'; exit 1; fi
	@size=$$(docker image inspect -f '{{.Size}}' "$(IMAGE)") && \
		if [ "$$size" -lt 600000000 ]; then printf 'Taille : %s octets, sous 600 Mo\n' "$$size"; \
		else printf 'Échec : %s octets, seuil de 600 Mo dépassé.\n' "$$size"; exit 1; fi
	$(MAKE) --no-print-directory docker-run
	$(MAKE) --no-print-directory docker-run-volume
	$(MAKE) --no-print-directory docker-output
