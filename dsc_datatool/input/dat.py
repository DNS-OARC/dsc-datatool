"""dsc_datatool.input.dat

Input plugin to generate `Dataset`'s from DSC DAT files.

Part of dsc_datatool.

:copyright: 2023 OARC, Inc.
"""

import re

from dsc_datatool import Input, Dataset, Dimension, process_dataset, encoding


_dataset1d = [
    'client_subnet_count',
    'ipv6_rsn_abusers_count',
]

_dataset2d = {
    'qtype':  'Qtype',
    'rcode':  'Rcode',
    'do_bit':  'D0',
    'rd_bit':  'RD',
    'opcode':  'Opcode',
    'dnssec_qtype':  'Qtype',
    'edns_version':  'EDNSVersion',
    'client_subnet2_count':  'Class',
    'client_subnet2_trace':  'Class',
    'edns_bufsiz':  'EDNSBufSiz',
    'idn_qname':  'IDNQname',
    'client_port_range':  'PortRange',
    'priming_responses':  'ReplyLen',
}

_dataset3d = {
    'chaos_types_and_names': [ 'Qtype', 'Qname' ],
    'certain_qnames_vs_qtype': [ 'CertainQnames', 'Qtype' ],
    'direction_vs_ipproto': [ 'Direction', 'IPProto' ],
    'pcap_stats': [ 'pcap_stat', 'ifname' ],
    'transport_vs_qtype': [ 'Transport', 'Qtype' ],
    'dns_ip_version': [ 'IPVersion', 'Qtype' ],
    'priming_queries': [ 'Transport', 'EDNSBufSiz' ],
    'qr_aa_bits': [ 'Direction', 'QRAABits' ],
}


class DAT(Input):
    def process(self, dir):
        global _dataset1d, _dataset2d, _dataset3d

        datasets = []

        for d in _dataset1d:
            if process_dataset and not d in process_dataset:
                continue
            try:
                datasets += self.process1d('%s/%s.dat' % (dir, d), d)
            except FileNotFoundError:
                pass
        for k, v in _dataset2d.items():
            if process_dataset and not k in process_dataset:
                continue
            try:
                datasets += self.process2d('%s/%s.dat' % (dir, k), k, v)
            except FileNotFoundError:
                pass
        for k, v in _dataset3d.items():
            if process_dataset and not k in process_dataset:
                continue
            try:
                datasets += self.process3d('%s/%s.dat' % (dir, k), k, v[0], v[1])
            except FileNotFoundError:
                pass

        return datasets


    def process1d(self, file, name):
        datasets = []
        with open(file, 'r', encoding=encoding) as f:
            for l in f.readlines():
                if re.match(r'^#', l):
                    continue
                l = re.sub(r'[\r\n]+$', '', l)
                dat = re.split(r'\s+', l)
                if len(dat) != 2:
                    raise Exception('DAT %r dataset %r: invalid number of elements for a 1d dataset' % (file, name))

                dataset = Dataset()
                dataset.name = name
                dataset.start_time = int(dat.pop(0))
                dataset.stop_time = dataset.start_time + 60

                d1 = Dimension('All')
                d1.values = { 'ALL': int(dat[0]) }
                dataset.dimensions.append(d1)

                datasets.append(dataset)

        return datasets


    def process2d(self, file, name, field):
        datasets = []
        with open(file, 'r', encoding=encoding) as f:
            for l in f.readlines():
                if re.match(r'^#', l):
                    continue
                l = re.sub(r'[\r\n]+$', '', l)
                dat = re.split(r'\s+', l)

                dataset = Dataset()
                dataset.name = name
                dataset.start_time = int(dat.pop(0))
                dataset.stop_time = dataset.start_time + 60

                d1 = Dimension('All')
                d1.value = 'ALL'
                dataset.dimensions.append(d1)

                d2 = Dimension(field)
                while dat:
                    if len(dat) < 2:
                        raise Exception('DAT %r dataset %r: invalid number of elements for a 2d dataset' % (file, name))
                    k = dat.pop(0)
                    v = dat.pop(0)
                    d2.values[k] = int(v)
                d1.dimensions.append(d2)

                datasets.append(dataset)

        return datasets


    def process3d(self, file, name, first, second):
        datasets = []
        with open(file, 'r', encoding=encoding) as f:
            for l in f.readlines():
                if re.match(r'^#', l):
                    continue
                l = re.sub(r'[\r\n]+$', '', l)
                dat = re.split(r'\s+', l)

                dataset = Dataset()
                dataset.name = name
                dataset.start_time = int(dat.pop(0))
                dataset.stop_time = dataset.start_time + 60

                while dat:
                    if len(dat) < 2:
                        raise Exception('DAT %r dataset %r: invalid number of elements for a 2d dataset' % (file, name))
                    k = dat.pop(0)
                    v = dat.pop(0)

                    d1 = Dimension(first)
                    d1.value = k
                    dataset.dimensions.append(d1)

                    d2 = Dimension(second)
                    dat2 = v.split(':')
                    while dat2:
                        if len(dat2) < 2:
                            raise Exception('DAT %r dataset %r: invalid number of elements for a 2d dataset' % (file, name))
                        k2 = dat2.pop(0)
                        v2 = dat2.pop(0)
                        d2.values[k2] = int(v2)
                    d1.dimensions.append(d2)

                datasets.append(dataset)

        return datasets


import sys
if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Input.__init_subclass__(DAT)
