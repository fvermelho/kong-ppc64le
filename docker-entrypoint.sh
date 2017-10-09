#!/usr/local/bin/dumb-init /bin/bash
set -e

# Disabling nginx daemon mode
export KONG_NGINX_DAEMON="off"

export PATH=$PATH:/opt/ibm/router/bin:/usr/local/kong/bin

kong migrations up 
exec "$@"

