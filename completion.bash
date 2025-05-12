#/usr/bin/env bash
complete -W "--branch --db-type --db-admin-pass --db-host --db-name --db-pass --db-port --db-user --docker-postgres-create --docker-postgres-name --docker-postgres-version --eclipse /
--help --http-host --http-port --https-port --load-idempiere-env --repository-url --skip-migration-script --skip-setup-ws --skip-setup-db --source --install-copilot /
--oracle-docker-container --oracle-docker-home" ./setup.sh
complete -W "--db-admin-pass --db-port --docker-postgres-name --docker-postgres-version" ./docker-postgres.sh
complete -W "--db-type --db-admin-pass --db-host --db-name --db-pass --db-port --db-user /
--help --http-host --http-port --https-port --run-migration-script --source --oracle-docker-container --oracle-docker-home" ./setup-db.sh
complete -W "--eclipse --source --help --install-copilot" ./setup-ws.sh
