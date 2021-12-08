#!/bin/bash


if [ -f /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID ]; then
  RECORD_ID=$(cat /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID)
  rm -f /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID
fi

# Remove the challenge TXT record from the zone

if [ -n "${RECORD_ID}" ]; then
  aliyun alidns DeleteDomainRecord --RecordId "${RECORD_ID}"
fi