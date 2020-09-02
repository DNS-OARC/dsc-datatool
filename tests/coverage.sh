#!/bin/sh

set -xe

base=`dirname $0`

export PATH="$base:$PATH"

"$base/test.sh"

! dsc-datatool \
  -vvv \
  -s test-server \
  -n test-node \
  --output ";InfluxDB;dml=1;database=dsc" \
  --transform ";Labler;*;yaml=$base/labler.yaml" \
  --transform ";ReRanger;rcode_vs_replylen;range=/64;pad_to=5" \
  --transform ";ReRanger;qtype_vs_qnamelen;range=/16;pad_to=3" \
  --transform ";ReRanger;client_port_range;key=low;range=/2048;pad_to=5" \
  --transform ";ReRanger;edns_bufsiz,priming_queries;key=low;range=/512;pad_to=5;allow_invalid_keys=1" \
  --transform ";ReRanger;priming_responses;key=low;range=/128;pad_to=4" \
  --transform ";NetRemap;client_subnet,client_subnet2,client_addr_vs_rcode,ipv6_rsn_abusers;net=16" \
  --generator ";client_subnet_authority;csv=$base/ipv4-address-space.csv;csv=$base/ipv6-unicast-address-assignments.csv" \
  --generator ";client_subnet_country;path=$HOME/GeoIP" \
  --xml "$base" >/dev/null

dsc-datatool \
  -vvv \
  -s test-server \
  -n test-node \
  --output ";InfluxDB;dml=1;database=dsc" \
  --transform ";ReRanger;rcode_vs_replylen;range=/64;pad_to=5" \
  --transform ";ReRanger;qtype_vs_qnamelen;range=/16;pad_to=3" \
  --transform ";ReRanger;client_port_range;key=low;range=/2048;pad_to=5" \
  --transform ";ReRanger;edns_bufsiz,priming_queries;key=low;range=/512;pad_to=5;allow_invalid_keys=1" \
  --transform ";ReRanger;priming_responses;key=low;range=/128;pad_to=4" \
  --transform ";NetRemap;client_subnet,client_subnet2,client_addr_vs_rcode,ipv6_rsn_abusers;net=16" \
  --generator ";client_subnet_authority;csv=$base/ipv4-address-space.csv;csv=$base/ipv6-unicast-address-assignments.csv" \
  --generator ";client_subnet_country;path=$HOME/GeoIP" \
  --dat "$base/20190719" >/dev/null

dsc-datatool -vvvvvvv --list >/dev/null
! dsc-datatool -s test -n test --output ";InfluxDB;test=a;test=b;test=c" >/dev/null
! dsc-datatool -s test -n test --generator does_not_exist >/dev/null
! dsc-datatool -s test -n test --generator does_not_exist,really_does_not_exist >/dev/null
! dsc-datatool -s test -n test --transform ";does_not_exist;*" >/dev/null
! dsc-datatool -s test -n test --transform ";ReRanger;a,a,a;range=/8" >/dev/null
! dsc-datatool -s test -n test --output does_not_exists >/dev/null
! dsc-datatool -s test -n test --dataset a --dataset b --dataset c,d,e >/dev/null
! dsc-datatool -s test -n test --dat "$base/coverage.sh" >/dev/null
