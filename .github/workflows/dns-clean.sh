#!/bin/bash


RECORD_ID="${CERTBOT_AUTH_OUTPUT}"

# Remove the challenge TXT record from the zone

if [ -n "${RECORD_ID}" ]; then
  aliyun alidns DeleteDomainRecord --RecordId "${RECORD_ID}"
fi