import yaml
import csv
from urllib.request import Request, urlopen
from io import StringIO

rcode = {}
qtype = {}
opcode = {}

for row in csv.reader(StringIO(urlopen(Request('http://www.iana.org/assignments/dns-parameters/dns-parameters-6.csv')).read().decode('utf-8'))):
    if row[0] == 'RCODE':
        continue
    rcode[row[0]] = row[1]

for row in csv.reader(StringIO(urlopen(Request('http://www.iana.org/assignments/dns-parameters/dns-parameters-4.csv')).read().decode('utf-8'))):
    if row[0] == 'TYPE':
        continue
    qtype[row[1]] = row[0]

for row in csv.reader(StringIO(urlopen(Request('http://www.iana.org/assignments/dns-parameters/dns-parameters-5.csv')).read().decode('utf-8'))):
    if row[0] == 'OpCode':
        continue
    opcode[row[0]] = row[1]

y = {}

for n in ['rcode', 'client_addr_vs_rcode', 'rcode_vs_replylen']:
    y[n] = { 'Rcode': {} }
    for k, v in rcode.items():
        y[n]['Rcode'][k] = v

for n in ['qtype', 'transport_vs_qtype', 'certain_qnames_vs_qtype', 'qtype_vs_tld', 'qtype_vs_qnamelen', 'chaos_types_and_names', 'dns_ip_version_vs_qtype']:
    y[n] = { 'Qtype': {} }
    for k, v in qtype.items():
        if v == '*':
            v = 'wildcard'
        y[n]['Qtype'][k] = v

for n in ['opcode']:
    y[n] = { 'Opcode': {} }
    for k, v in rcode.items():
        y[n]['Opcode'][k] = v

print(yaml.dump(y, explicit_start=True, default_flow_style=False))
