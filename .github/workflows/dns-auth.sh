#!/bin/bash

# certbot certonly --manual -n --agree-tos --email hu2008yinxiang@163.com --preferred-challenges=dns --manual-auth-hook /root/homebrew-clipy/.github/workflows/dns-auth.sh --manual-cleanup-hook /root/homebrew-clipy/.github/workflows/dns-clean.sh -d 'mi-core.com,*.mi-core.com' --logs-dir /tmp --work-dir .  --config-dir /opt/certs
# certbot renew --manual --logs-dir /tmp --work-dir /tmp  --config-dir /tmp



which ggrep 2>/dev/null && alias grep=ggrep || true

# Strip only the top domain to get the zone id
DOMAIN=$(echo "$CERTBOT_DOMAIN" | grep -oP '[^\.]*\.[^\.]*$')

# Get old TXT record
OLD_RECORD_ID=$(aliyun alidns DescribeDomainRecords \
  --DomainName "${DOMAIN}" \
  --Type TXT \
  --SearchMode EXACT \
  --KeyWord _acme-challenge \
  | jq -r '.DomainRecords.Record | map(.RecordId) | join(" ") '\
)

# Delete old TXT record
aliyun alidns DescribeDomainRecords \
  --DomainName "${DOMAIN}" \
  --Type TXT \
  --SearchMode EXACT \
  --KeyWord _acme-challenge \
  | jq -r '.DomainRecords.Record[].RecordId ' \
  | while read OLD_RECORD_ID_I || [[ -n "$OLD_RECORD_ID_I" ]]; do
    aliyun alidns DeleteDomainRecord --RecordId "${OLD_RECORD_ID_I}"
  done

# Add new TXT record
NEW_RECORD_ID=$(aliyun alidns AddDomainRecord \
  --Type TXT \
  --DomainName "${DOMAIN}" \
  --RR _acme-challenge \
  --Value "$CERTBOT_VALIDATION" \
  | jq -r .RecordId \
)

# Save info for cleanup
if [ ! -d /tmp/CERTBOT_$CERTBOT_DOMAIN ];then
        mkdir -m 0700 /tmp/CERTBOT_$CERTBOT_DOMAIN
fi
echo $NEW_RECORD_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID

# Sleep to make sure the change has time to propagate over to DNS
sleep 25