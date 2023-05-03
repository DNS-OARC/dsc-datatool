"""dsc_datatool.output.influxdb

See `man dsc-datatool-output influxdb`.

Part of dsc_datatool.

:copyright: 2022 OARC, Inc.
"""

import re
import sys
import atexit

from dsc_datatool import Output, args


_re = re.compile(r'([,=\s])')


def _key(key):
    return re.sub(_re, r'\\\1', key)


def _val(val):
    ret = re.sub(_re, r'\\\1', val)
    if ret == '':
        return '""'
    return ret


def _process(tags, timestamp, dimension, fh):
    if dimension.dimensions is None:
        return

    if len(dimension.dimensions) > 0:
        if not (dimension.name == 'All' and dimension.value == 'ALL'):
            tags += ',%s=%s' % (_key(dimension.name.lower()), _val(dimension.value))
        for d2 in dimension.dimensions:
            _process(tags, timestamp, d2, fh)
        return

    if dimension.values is None:
        return

    if len(dimension.values) > 0:
        tags += ',%s=' % _key(dimension.name.lower())

        for k, v in dimension.values.items():
            print('%s%s value=%s %s' % (tags, _val(k), v, timestamp), file=fh)


class InfluxDB(Output):
    start_timestamp = True
    fh = None


    def __init__(self, opts):
        Output.__init__(self, opts)
        timestamp = opts.get('timestamp', 'start')
        if timestamp == 'start':
            pass
        elif timestamp == 'stop':
            self.start_timestamp = False
        else:
            raise Exception('timestamp option invalid')
        file = opts.get('file', None)
        append = opts.get('append', False)
        if file:
            if append:
                self.fh = open(file, 'a', encoding="utf-8")
            else:
                self.fh = open(file, 'w', encoding="utf-8")
            atexit.register(self.close)
        else:
            self.fh = sys.stdout

        if opts.get('dml', False):
            print('# DML', file=self.fh)
            database = opts.get('database', None)
            if database:
                print('# CONTEXT-DATABASE: %s' % database, file=self.fh)


    def close(self):
        if self.fh:
            self.fh.close()
            self.fh = None


    def process(self, datasets):
        for dataset in datasets:
            tags = '%s,server=%s,node=%s' % (_key(dataset.name.lower()), args.server, args.node)
            if self.start_timestamp:
                timestamp = dataset.start_time * 1000000000
            else:
                timestamp = dataset.end_time * 1000000000

            for d in dataset.dimensions:
                _process(tags, timestamp, d, self.fh)


if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Output.__init_subclass__(InfluxDB)
