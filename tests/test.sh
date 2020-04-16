#!/bin/sh -xe

dsc-datatool \
  -vvv \
  -s test-server \
  -n test-node \
  --output ";InfluxDB;dml=1;database=dsc" \
  --transform ";Labler;*;yaml=./labler.yaml" \
  --transform ";ReRanger;rcode_vs_replylen;range=/64;pad_to=5" \
  --transform ";ReRanger;qtype_vs_qnamelen;range=/16;pad_to=3" \
  --transform ";ReRanger;client_port_range;key=low;range=/2048;pad_to=5" \
  --transform ";ReRanger;edns_bufsiz,priming_queries;key=low;range=/512;pad_to=5;allow_invalid_keys=1" \
  --transform ";ReRanger;priming_responses;key=low;range=/128;pad_to=4" \
  --transform ";NetRemap;client_subnet,client_subnet2,client_addr_vs_rcode,ipv6_rsn_abusers;net=16" \
  --generator ";client_subnet_authority;csv=ipv4-address-space.csv;csv=ipv6-unicast-address-assignments.csv" \
  --xml ./1563520620.dscdata.xml > test.out

diff -u test.gold test.out
