#!/bin/sh -xe

base=`dirname $0`

dsc-datatool \
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
  --xml "$base/1563520620.dscdata.xml" | sort -s > "$base/test.out"

sort -s "$base/test.gold" > "$base/test.gold.tmp"
diff -u "$base/test.gold.tmp" "$base/test.out"

dsc-datatool \
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
  --dat "$base/20190719" | sort -s > "$base/test.out"

sort -s "$base/test.gold2" > "$base/test.gold2.tmp"
diff -u "$base/test.gold2.tmp" "$base/test.out"

dsc-datatool \
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
  --xml "$base/1458044657.xml" | sort -s > "$base/test.out"

sort -s "$base/test.gold3" > "$base/test.gold3.tmp"
diff -u "$base/test.gold3.tmp" "$base/test.out"

dsc-datatool \
  -vvv \
  -s test-server-åäö \
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
  --xml "$base/utf8.xml" | sort -s > "$base/test.out"

sort -s "$base/test.gold4" > "$base/test.gold4.tmp"
diff -u "$base/test.gold4.tmp" "$base/test.out"
