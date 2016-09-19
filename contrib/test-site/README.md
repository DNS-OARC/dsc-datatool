# DSC Test Site Files

These files are used for the [DSC Grafana test site](https://dev.dns-oarc.net/dsc-grafana/dashboard/db/dsc),
read [this wiki](https://github.com/DNS-OARC/dsc-datatool/wiki/Setting-up-a-test-Grafana) on how to set it up yourself.

# Types

- trace
  y:time
  x:values
  timed based graph

- accum1d
  y:index2
  x:index1
  vbar:value
  horizontal bars with label showing data, colors per node

- accum2d
  y:index2
  x:index1
  vbar:values
  horizontal bars with label showing multiple data in different colors

- hist2d
  y:index1
  x:index2
  vertical bars with label as data showing multiple data in different colors

# Notes

- client subnet size need to be configurable because of number of files and
  directories it will create (a=255*ndata, b=255*255*ndata, c=255*255*255*ndata)
- valid/invalid tlds are configured

# Alias

Short | Full
----- | ----
cnet | client_subnet
qclassif | query_classification
qvt | qtype_vs_tld
qvat | qtype_vs_all_tld
qvit | qtype_vs_invalid_tld
itld | invalid_tld
qvvt | qtype_vs_valid_tld
vtld | valid_tld
qvnt | qtype_vs_numeric_tld
ntld | numeric_tld
dvi | direction_vs_ipproto
div | dns_ip_version
tvq | transport_vs_qtype
qvq | qtype_vs_qnamelen
rvr | rcode_vs_replylen
cavra | client_addr_vs_rcode_accum
iraa | ipv6_rsn_abusers_accum
ctan | chaos_types_and_names
cp | client_port
lvra | ld_vs_rcode_accum
p | priming

# Graphs

Name | Type | Dataset | Y-axis | X-axis | Labels
---- | ---- | --------- | ------ | ------ | ------
bynode | trace | qtype | time | sum(node) | nodes
qtype | trace | qtype | time | sum(qtype) | qtypes
dnssec_qtype | trace | dnssec_qtype | time | cnt(rr) | rrs
rcode | trace | rcode | time | sum(rcode) | rcodes
opcode | trace | opcode | time | sum(opcode) | opcodes
cnet_accum | accum1d | cnet_accum | qps(subnet) | subnet/country | rirs
cnet | trace | cnet | time | subnets
cnet2_accum | accum2d | cnet2_accum | qps(subnet) | subnet | qclassifs
cnet2_trace | trace | cnet2_trace | time | cnt(qclassif) | qclassifs
cnet2_count | trace | cnet2_count | time | cnt(subnet) | qclassifs
qvat | accum2d | qvt | qps(tld) | tld | qtypes
qvit | accum2d | qvt | qps(itld) | itld | qtypes
qvvt | accum2d | qvt | qps(vtld) | vtld | qtypes
qvnt | accum2d | qvt | qps(ntld) | ntld | qtypes
dvi | trace | dvi(recv) | time | pps(proto) | protos
div | trace | div | time | qps(ipv) | ipvs
div_vs_qtype | accum2d | div_vs_qtype | qps(ipv) | ipv | qtypes
tvq | trace | tvq | time | qps(proto) | protos
dvi_sent | trace | dvi(sent) | time | pps(proto) | protos
direction | trace | dvi | time | pps(sent/recv) | sent/recv
idn_qname | trace | idn_qname | time | sum(idn(q))
rd_bit | trace | rd_bit | time | sum(rd_bit(q))
tc_bit | trace | tc_bit | time | sum(tc_bit(q))
do_bit | trace | do_bit | time | sum(do_bit(q))
edns_version | trace | edns_version | time | cnt(version) | versions
qvq | hist2d | qvq | bytes | qcnt | qtypes
rvr | hist2d | rvr | bytes | qcnt | rcodes
cavra | accum2d | cavra | qps(ip) | ip | rcodes
iraa | accum1d | iraa | qps(ip) | ip | hostids
ctan | trace | ctan | time | cnt(dnsid) | dnsids
cps_count | trace | cps | time | cnt(uniq(port))
cp_range | trace | cps | time | pcnt(range) | ranges
edns_bufsiz | trace | edns_bufsiz | time | pcnt(range) | ranges
second_lvra | accum2d | second_lvra | qps(2ld) | 2ld | rcodes
third_lvra | accum2d | third_lvra | qps(3ld) | 3ld | rcodes
pcap_stats | trace | pcap_stats | time | pps(stat) | stats
p_queries | trace | p_queries | time | cnt(proto) | protos
p_responses | trace | p_responses | time | min/mean/max(size)
qr_aa_bits | trace | qr_aa_bits | time | cnt(qraa,qrAA,QRaa,QRAA)

# TODO

certain_qnames_vs_qtype
