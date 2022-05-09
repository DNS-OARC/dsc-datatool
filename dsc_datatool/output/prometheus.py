"""dsc_datatool.output.prometheus

See `man dsc-datatool-output prometheus`.

Part of dsc_datatool.

:copyright: 2022 OARC, Inc.
"""

import re
import sys
import atexit

from dsc_datatool import Output, args


_re = re.compile(r'([\\\n"])')


def _key(key):
    return re.sub(_re, r'\\\1', key)


def _val(val):
    ret = re.sub(_re, r'\\\1', val)
    if ret == '':
        return '""'
    return '"%s"' % ret


class Prometheus(Output):
    show_timestamp = True
    start_timestamp = True
    fh = None
    type_def = ''
    type_printed = False
    prefix = ''


    def __init__(self, opts):
        Output.__init__(self, opts)
        timestamp = opts.get('timestamp', 'start')
        if timestamp == 'hide':
            self.show_timestamp = False
        elif timestamp == 'start':
            pass
        elif timestamp == 'stop':
            self.start_timestamp = False
        else:
            raise Exception('timestamp option invalid')
        file = opts.get('file', None)
        append = opts.get('append', False)
        if file:
            if append:
                self.fh = open(file, 'a')
            else:
                self.fh = open(file, 'w')
            atexit.register(self.close)
        else:
            self.fh = sys.stdout
        self.prefix = opts.get('prefix', '')


    def close(self):
        if self.fh:
            self.fh.close()
            self.fh = None


    def _process(self, tags, timestamp, dimension, fh):
        if dimension.dimensions is None:
            return

        if len(dimension.dimensions) > 0:
            if not (dimension.name == 'All' and dimension.value == 'ALL'):
                tags += ',%s=%s' % (_key(dimension.name.lower()), _val(dimension.value))
            for d2 in dimension.dimensions:
                self._process(tags, timestamp, d2, fh)
            return

        if dimension.values is None:
            return

        if len(dimension.values) > 0:
            tags += ',%s=' % _key(dimension.name.lower())

            for k, v in dimension.values.items():
                if not self.type_printed:
                    print(self.type_def, file=fh)
                    self.type_printed = True
                if self.show_timestamp:
                    print('%s%s} %s %s' % (tags, _val(k), v, timestamp), file=fh)
                else:
                    print('%s%s} %s' % (tags, _val(k), v), file=fh)


    def process(self, datasets):
        for dataset in datasets:
            self.type_def = '# TYPE %s gauge' % _key(dataset.name.lower())
            self.type_printed = False
            tags = '%s%s{server=%s,node=%s' % (self.prefix, _key(dataset.name.lower()), _val(args.server), _val(args.node))
            if self.start_timestamp:
                timestamp = dataset.start_time * 1000
            else:
                timestamp = dataset.end_time * 1000

            for d in dataset.dimensions:
                self._process(tags, timestamp, d, self.fh)


if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Output.__init_subclass__(Prometheus)
