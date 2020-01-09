DB_PORT=${DB_PORT:-5432}
DB_SYSTEM=${DB_SYSTEM:-postgres}
docker run -d --name postgres -p $DB_PORT:5432 -e POSTGRES_PASSWORD=$DB_SYSTEM postgres:9.6
