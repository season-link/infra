#!/bin/sh

# env vars
# KEYCLOAK_VALID_REDIRECT_URIS - comma separated list of valid redirect uris
# KEYCLOAK_ADMIN_USER
# KEYCLOAK_ADMIN_PASSWORD
# KEYCLOAK_HOST
# KEYCLOAK_NEW_REALM
# KEYCLOAK_NEW_CLIENT_ID
# KEYCLOAK_NEW_CLIENT_SECRET
# KEYCLOAK_NEW_USER
# KEYCLOAK_NEW_PASSWORD
# DEV

set -e

# init a keycloak realm
export PATH="$PATH":/opt/bitnami/keycloak/bin

echo "Authenticating to keycloak at '$KEYCLOAK_HOST'"

kcadm.sh config credentials \
    --config /tmp/config \
    --server "http://$KEYCLOAK_HOST" \
    --user "$KEYCLOAK_ADMIN_USER" \
    --password "$KEYCLOAK_ADMIN_PASSWORD" \
    --realm master

# if realm already exists, exit

echo "Checking if realm '$KEYCLOAK_NEW_REALM' already exists"

set +e

if kcadm.sh get realms \
    --config /tmp/config \
    --server "http://$KEYCLOAK_HOST" \
    --realm master \
    --fields realm |
    grep -qs "$KEYCLOAK_NEW_REALM"; then
    echo "Realm '$KEYCLOAK_NEW_REALM' already exists"
    exit 0
fi

set -e

echo "Creating realm '$KEYCLOAK_NEW_REALM'"

NEW_REALM_ID=$(kcadm.sh create realms \
    --config /tmp/config \
    -s realm="$KEYCLOAK_NEW_REALM" \
    -s enabled=true \
    -s resetPasswordAllowed=true \
    -o)

if [ -z "$NEW_REALM_ID" ]; then
    echo "Failed to create realm '$KEYCLOAK_NEW_REALM'"
    exit 1
fi

# create client

echo "Creating client '$KEYCLOAK_NEW_CLIENT_ID'"

echo "Auth redirect uris: $KEYCLOAK_VALID_REDIRECT_URIS"

NEW_CLIENT_ID=$(kcadm.sh create clients \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s redirectUris="$KEYCLOAK_VALID_REDIRECT_URIS" \
    -s name="$KEYCLOAK_NEW_CLIENT_ID" \
    -s clientId="$KEYCLOAK_NEW_CLIENT_ID" \
    -s enabled=true \
    -s directAccessGrantsEnabled=true \
    -s standardFlowEnabled=true \
    -s implicitFlowEnabled=false \
    -s publicClient=true \
    -s frontchannelLogout=false \
    -s serviceAccountsEnabled=false \
    -s secret="$KEYCLOAK_NEW_CLIENT_SECRET" \
    --fields id \
    -o)

NEW_CLIENT_ID=$(echo "$NEW_CLIENT_ID" | sed -n 's/.*"id" : "\(.*\)".*/\1/p')

echo "$NEW_CLIENT_ID"

# Adding admin and user roles to realm

echo "Adding client_user role and client_admin role to client '$KEYCLOAK_NEW_CLIENT_ID'"

kcadm.sh create clients/"$NEW_CLIENT_ID"/roles \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s name=client_candidate \
    -s description="User related to candidates actions"

kcadm.sh create clients/"$NEW_CLIENT_ID"/roles \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s name=client_admin \
    -s description="User related to administration actions"

echo "Adding candidate and admin role to realm '$KEYCLOAK_NEW_REALM'"

kcadm.sh create roles \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s name=candidate \
    -s 'description=Candidate role'

kcadm.sh create roles \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s name=admin \
    -s 'description=Admin role'

kcadm.sh add-roles \
    --rname candidate \
    --cclientid "$KEYCLOAK_NEW_CLIENT_ID" \
    --rolename client_candidate \
    -r "$KEYCLOAK_NEW_REALM" \
    --config /tmp/config

kcadm.sh add-roles \
    --rname admin \
    --cclientid "$KEYCLOAK_NEW_CLIENT_ID" \
    --rolename client_admin \
    -r "$KEYCLOAK_NEW_REALM" \
    --config /tmp/config

# create default user for smtp

echo "Creating default user '$KEYCLOAK_NEW_USER'"

kcadm.sh create users \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    -s username="$KEYCLOAK_NEW_USER" \
    -s email="$KEYCLOAK_NEW_USER" \
    -s enabled=true \
    -s emailVerified=true \
    -s firstName=Default \
    -s lastName=User

kcadm.sh set-password \
    --config /tmp/config \
    -r "$KEYCLOAK_NEW_REALM" \
    --username "$KEYCLOAK_NEW_USER" \
    --new-password "$KEYCLOAK_NEW_PASSWORD"

echo "Configuring SMTP"

kcadm.sh update \
    --config=/tmp/config \
    realms/"$KEYCLOAK_NEW_REALM" \
    -s "smtpServer.host=$KEYCLOAK_SMTP_HOST" \
    -s "smtpServer.port=$KEYCLOAK_SMTP_PORT" \
    -s "smtpServer.from=contact@season-link.com" \
    -s "smtpServer.fromDisplayName=Season Link" \
    -s "smtpServer.starttls=true" \
    -s "smtpServer.auth=true" \
    -s "smtpServer.user=$KEYCLOAK_SMTP_USER" \
    -s "smtpServer.password=$KEYCLOAK_SMTP_PASSWORD"

# Adding dev users
if [ "$DEV" = "true" ]; then
    echo "Adding dev users"

    kcadm.sh create users \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        -s enabled=true \
        -s emailVerified=true \
        -s username="candidate" \
        -s email="candidate@season-link.com" \
        -s firstName=Candidate \
        -s lastName=User

    kcadm.sh set-password \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        --username "candidate" \
        --new-password "candidate"

    kcadm.sh add-roles \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        --uusername "candidate" \
        --rolename candidate

    kcadm.sh create users \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        -s enabled=true \
        -s emailVerified=true \
        -s username="admin" \
        -s email="admin@season-link.com" \
        -s firstName=Admin \
        -s lastName=User

    kcadm.sh set-password \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        --username "admin" \
        --new-password "admin"


    kcadm.sh add-roles \
        --config /tmp/config \
        -r "$KEYCLOAK_NEW_REALM" \
        --uusername "admin" \
        --rolename admin
fi

echo "Success"
