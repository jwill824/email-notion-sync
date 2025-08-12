curl -sSL https://aspire.dev/install.sh | bash
export ASPNETCORE_URLS="http://localhost:18888"
export ASPIRE_DASHBOARD_OTLP_HTTP_ENDPOINT_URL="http://localhost:4318"
export ASPIRE_ALLOW_UNSECURED_TRANSPORT="true"
apt-get update
apt-get install -y libc6 libgcc1 libgssapi-krb5-2 libstdc++6 zlib1g libunwind8 libicu-dev
npm install -g azure-functions-core-tools@4 --unsafe-perm true