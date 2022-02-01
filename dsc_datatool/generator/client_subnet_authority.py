"""dsc_datatool.generator.client_subnet_authority

See `man dsc-datatool-generator client_subnet_authority`.

Part of dsc_datatool.

:copyright: 2022 OARC, Inc.
"""

import csv
import ipaddress
import logging
from urllib.request import Request, urlopen
from io import StringIO

from dsc_datatool import Generator, Dataset, Dimension, args


_whois2rir = {
    'whois.apnic.net': 'APNIC',
    'whois.arin.net': 'ARIN',
    'whois.ripe.net': 'RIPE NCC',
    'whois.lacnic.net': 'LACNIC',
    'whois.afrinic.net': 'AFRINIC',
}

_desig2rir = {
    'apnic': 'APNIC',
    'arin': 'ARIN',
    'ripe ncc': 'RIPE NCC',
    'lacnic': 'LACNIC',
    'afrinic': 'AFRINIC',
    'iana': 'IANA',
    '6to4': 'IANA',
}

class client_subnet_authority(Generator):
    auth = None


    def _read(self, input):
        global _whois2rir, _desig2rir
        for row in csv.reader(input):
            prefix, designation, date, whois, rdap, status, note = row
            if prefix == 'Prefix':
                continue
            rir = designation.replace('Administered by ', '').lower()

            whois = whois.lower()
            if whois in _whois2rir:
                rir = _whois2rir[whois]
            else:
                if rir in _desig2rir:
                    rir = _desig2rir[rir]
                else:
                    found = None
                    for k, v in _desig2rir.items():
                        if k in rir:
                            found = v
                            break
                    if found:
                        rir = found
                    else:
                        if status == 'RESERVED':
                            rir = 'IANA'
                        else:
                            raise Exception('Unknown whois/designation: %r/%r' % (whois, designation))

            try:
                net = ipaddress.ip_network(prefix)
            except Exception:
                ip, net = prefix.split('/')
                net = ipaddress.ip_network('%s.0.0.0/%s' % (int(ip), net))

            if net.version == 4:
                idx = ipaddress.ip_network('%s/8' % net.network_address, strict=False)
            else:
                idx = ipaddress.ip_network('%s/24' % net.network_address, strict=False)

            if idx.network_address in self.auth:
                self.auth[idx.network_address].append({'net': net, 'auth': rir})
            else:
                self.auth[idx.network_address] = [{'net': net, 'auth': rir}]


    def __init__(self, opts):
        Generator.__init__(self, opts)
        self.auth = {}
        csvs = opts.get('csv', None)
        urlv4 = opts.get('urlv4', 'https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.csv')
        urlv6 = opts.get('urlv6', 'https://www.iana.org/assignments/ipv6-unicast-address-assignments/ipv6-unicast-address-assignments.csv')
        if csvs:
            if not isinstance(csvs, list):
                csvs = [ csvs ]
            for file in csvs:
                with open(file, newline='') as csvfile:
                    self._read(csvfile)
        elif opts.get('fetch', 'no').lower() == 'yes':
            urls = opts.get('url', [ urlv4, urlv6 ])
            if urls and not isinstance(urls, list):
                urls = [ urls ]
            logging.info('bootstrapping client subnet authority using URLs')
            for url in urls:
                logging.info('fetching %s' % url)
                self._read(StringIO(urlopen(Request(url)).read().decode('utf-8')))
        else:
            raise Exception('No authorities bootstrapped, please specify csv= or fetch=yes')


    def process(self, datasets):
        gen_datasets = []

        for dataset in datasets:
            if dataset.name != 'client_subnet':
                continue

            subnets = {}
            for d1 in dataset.dimensions:
                for d2 in d1.dimensions:
                    for k, v in d2.values.items():
                        if k == args.skipped_key:
                            continue
                        elif k == args.skipped_sum_key:
                            continue

                        if k in subnets:
                            subnets[k] += v
                        else:
                            subnets[k] = v

            auth = {}
            for subnet in subnets:
                ip = ipaddress.ip_address(subnet)
                if ip.version == 4:
                    idx = ipaddress.ip_network('%s/8' % ip, strict=False)
                    ip = ipaddress.ip_network('%s/32' % ip)
                else:
                    idx = ipaddress.ip_network('%s/24' % ip, strict=False)
                    ip = ipaddress.ip_network('%s/128' % ip)
                if not idx.network_address in self.auth:
                    idx = '??'
                else:
                    for entry in self.auth[idx.network_address]:
                        if entry['net'].overlaps(ip):
                            idx = entry['auth']
                            break

                if idx in auth:
                    auth[idx] += subnets[subnet]
                else:
                    auth[idx] = subnets[subnet]

            if auth:
                authd = Dataset()
                authd.name = 'client_subnet_authority'
                authd.start_time = dataset.start_time
                authd.stop_time = dataset.stop_time
                gen_datasets.append(authd)

                authd1 = Dimension('ClientAuthority')
                authd1.values = auth
                authd.dimensions.append(authd1)

        return gen_datasets


import sys
if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Generator.__init_subclass__(client_subnet_authority)
