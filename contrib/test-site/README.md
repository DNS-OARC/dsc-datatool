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

 ?  | Name | Type | Dataset | Y-axis | X-axis | Labels
--- | ---- | ---- | --------- | ------ | ------ | ------
OK | bynode | trace | qtype | time | qps(node) | nodes
OK | qtype | trace | qtype | time | qps(qtype) | qtypes
ok | dnssec_qtype | trace | dnssec_qtype | time | cnt(rr) | rrs
OK | rcode | trace | rcode | time | qps(rcode) | rcodes
OK | opcode | trace | opcode | time | qps(opcode) | opcodes
CD | cnet_accum | accum1d | cnet_accum | qps(subnet) | subnet/country | rirs
OK | cnet | trace | cnet | time | subnets
CD | cnet2_accum | accum2d | cnet2_accum | qps(subnet) | subnet | qclassifs
OK | cnet2_trace | trace | cnet2_trace | time | cnt(qclassif) | qclassifs
OK | cnet2_count | trace | cnet2_count | time | cnt(subnet) | qclassifs
OK | qvat | accum2d | qvt | qps(tld) | tld | qtypes
CD | qvit | accum2d | qvt | qps(itld) | itld | qtypes
CD | qvvt | accum2d | qvt | qps(vtld) | vtld | qtypes
CD | qvnt | accum2d | qvt | qps(ntld) | ntld | qtypes
OK | dvi | trace | dvi(recv) | time | pps(proto) | protos
ND | div | trace | div | time | qps(ipv) | ipvs
OK | div_vs_qtype | accum2d | div_vs_qtype | qps(ipv) | ipv | qtypes
OK | tvq | trace | tvq | time | qps(proto) | protos
OK | dvi_sent | trace | dvi(sent) | time | pps(proto) | protos
OK | direction | trace | dvi | time | pps(sent/recv) | sent/recv
OK | idn_qname | trace | idn_qname | time | sum(idn(q))
OK | rd_bit | trace | rd_bit | time | sum(rd_bit(q))
NX | tc_bit | trace | tc_bit | time | sum(tc_bit(q))
OK | do_bit | trace | do_bit | time | sum(do_bit(q))
OK | edns_version | trace | edns_version | time | qps(version) | versions
OK | qvq | hist2d | qvq | bytes | qcnt | qtypes
OK | rvr | hist2d | rvr | bytes | qcnt | rcodes
OK | cavra | accum2d | cavra | qps(ip) | ip | rcodes
OK | iraa | accum1d | iraa | qps(ip) | ip | hostids
OK | ctan | trace | ctan | time | cnt(dnsid) | dnsids
CD | cps_count | trace | cps | time | cnt(uniq(port))
OK | cp_range | trace | cps | time | pcnt(range) | ranges
OK | edns_bufsiz | trace | edns_bufsiz | time | pcnt(range) | ranges
NX | second_lvra | accum2d | second_lvra | qps(2ld) | 2ld | rcodes
NX | third_lvra | accum2d | third_lvra | qps(3ld) | 3ld | rcodes
OK | pcap_stats | trace | pcap_stats | time | pps(stat) | stats
OK | p_queries | trace | p_queries | time | cnt(proto) | protos
OK | p_responses | trace | p_responses | time | min/mean/max(size)
OK | qr_aa_bits | trace | qr_aa_bits | time | cnt(qraa,qrAA,QRaa,QRAA)

Legends:
- OK: Graphs is done
- ok: Graph can be created from other data
- CD: Need to create data
- ND: Had no data to create graph on
- NX: No data exists for this at all

# InfluxDB

```
--output ";InfluxDB" --transform ";Labler;*;yaml=$HOME/labler.yaml" --transform ";ReRanger;rcode_vs_replylen;range=/64;pad_to=5" --transform ";ReRanger;qtype_vs_qnamelen;range=/16;pad_to=3" --transform ";ReRanger;client_port_range;key=low;range=/2048;pad_to=5" --transform ";ReRanger;edns_bufsiz,priming_queries;key=low;range=/512;pad_to=5;allow_invalid_keys=1" --transform ";ReRanger;priming_responses;key=low;range=/128;pad_to=4" --transform ";NetRemap;client_subnet,client_subnet2,client_addr_vs_rcode,ipv6_rsn_abusers;net=8"
```

# TODO

certain_qnames_vs_qtype
