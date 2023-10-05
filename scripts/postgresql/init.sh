#!/bin/sh

set -e

# Create a new user, database and grant all privileges on database
# Uses postgres user to create the new user and database
# If the database already exists, it will exit with success
# $1: new user
# $2: new user password
# $3: new database
create_database() {
	NEW_USER=$1
	NEW_PASSWORD=$2
	NEW_DB=$3

	echo "Creating user '$NEW_USER' and database '$NEW_DB'"

	# check if database exists
	CHECK_DB=$(psql "postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@127.0.0.1/$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='$NEW_DB'")


	if [ "$CHECK_DB" = "1" ]; then
		echo "Database '$NEW_DB' already exists"
	else
		psql "postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@127.0.0.1/postgres" -v ON_ERROR_STOP=1  <<-EOSQL
			CREATE USER $NEW_USER WITH PASSWORD '$NEW_PASSWORD';
			CREATE DATABASE $NEW_DB;
			GRANT ALL PRIVILEGES ON DATABASE $NEW_DB TO $NEW_USER;
		EOSQL

		echo "User '$NEW_USER' and database '$NEW_DB' created"
	fi
}

# Create keycloak database
create_database "$KEYCLOAK_DB" "$KEYCLOAK_USER" "$KEYCLOAK_PASSWORD"
