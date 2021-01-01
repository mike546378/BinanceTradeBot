#!/bin/bash
#cd /app && mix phx.new jormungandr --umbrella

baseDir=/app/$APPNAME"_umbrella"
webApp=$baseDir/apps/$APPNAME"_web"

while ! pg_isready -U $PGUSER -h $PGHOST -p $PGPORT; do
  echo "$(date) - waiting for database to start"
  sleep 2
done

if [ ! -d $baseDir ]; then
  echo "Creating project structure"
  cd /app/
  printf 'n\n' | mix phx.new $APPNAME --umbrella
  echo "Created project structure"
fi

if [ ! -f $webApp/assets/tsconfig.json ]; then
  echo "Copying initial configs"
  cp -R $baseDir/../initconfigs/* $webApp/assets/
fi

echo "Building dependancies"
cd $baseDir && mix deps.get
cd $webApp/assets && npm install --save-dev -y && node node_modules/webpack/bin/webpack.js --mode development

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "Database $PGDATABASE does not exist. Creating..."
  cd $baseDir
  createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0
  mix ecto.migrate
  mix run apps/$APPNAME/priv/repo/seeds.exs
  echo "Database $PGDATABASE created."
fi

echo "Migrating database $PGDATABASE..."
cd $baseDir/apps/$APPNAME
mix ecto.migrate

cd $baseDir
mix phx.server

