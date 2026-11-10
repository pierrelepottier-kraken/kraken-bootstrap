avec la protection activée, je dois passer une PR pour envoyer mes changes sur `main`.
`kraken / lint-test` vérifie le code avec Ruff et les tests : si ça casse, je ne pourrai pas merge.
`kraken / build-push` doit aussi passer, donc le Dockerfile qui ne construit plus l'image bloquera aussi la PR.
