#ddev-generated
## This script overwrite the no-router adminer configuration with the default one, so when you run autoupdate
## on no-router environment, the adminer configuration is not overwritten.
pwd
cat <<EOF > docker-compose.adminer_norouter.yaml
#ddev-generated
# If omit_containers[ddev-router] then this file will be replaced
# with another with a \`ports\` statement to directly expose port 8080 to 9100
services: {}
EOF