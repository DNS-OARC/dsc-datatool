"""dsc_datatool.transformer.re_ranger

See `man dsc-datatool-transformer reranger`.

Part of dsc_datatool.

:copyright: 2020 OARC, Inc.
"""

import re

from dsc_datatool import Transformer, args


_key_re = re.compile(r'^(?:(\d+)|(\d+)-(\d+))$')


class ReRanger(Transformer):
    key = None
    func = None
    allow_invalid_keys = None
    range = None
    split_by = None


    def __init__(self, opts):
        Transformer.__init__(self, opts)
        self.key = opts.get('key', 'mid')
        self.func = opts.get('func', 'sum')
        self.allow_invalid_keys = opts.get('allow_invalid_keys', False)
        self.range = opts.get('range', None)

        if self.allow_invalid_keys != False:
            self.allow_invalid_keys = True

        if self.range is None:
            raise Exception('range must be given')
        m = re.match(r'^/(\d+)$', self.range)
        if m is None:
            raise Exception('invalid range')
        self.split_by = int(m.group(1))

        if self.key != 'low' and self.key != 'mid' and self.key != 'high':
            raise Exception('invalid key %r' % self.key)

        if self.func != 'sum':
            raise Exception('invalid func %r' % self.func)


    def _process(self, dimension):
        global _key_re

        if not dimension.values:
            for d2 in dimension.dimensions:
                self._process(d2)
            return

        values = dimension.values
        dimension.values = {}
        skipped = None

        for k, v in values.items():
            low = None
            high = None

            m = _key_re.match(k)
            if m:
                low, low2, high = m.group(1, 2, 3)
                if high is None:
                    low = int(low)
                    high = low
                else:
                    low = int(low2)
                    high = int(high)
            elif k == args.skipped_key:
                continue
            elif k == args.skipped_sum_key:
                if skipped is None:
                    skipped = v
                else:
                    skipped += v
                continue
            elif self.allow_invalid_keys:
                dimension.values[k] = v
                continue
            else:
                raise Exception('invalid key %r' % k)

            if self.key == 'low':
                nkey = low
            elif self.key == 'mid':
                nkey = int(low + ( (high - low) / 2 ))
            else:
                nkey = high

            nkey = int(nkey / self.split_by) * self.split_by
            low = nkey
            high = nkey + self.split_by - 1

            if self.func == 'sum':
                if low != high:
                    nkey = '%d-%d' % (low, high)
                else:
                    nkey = str(nkey)

                if nkey in dimension.values:
                    dimension.values[nkey] += v
                else:
                    dimension.values[nkey] = v

        if skipped:
            dimension.values['skipped'] = skipped


    def process(self, datasets):
        for dataset in datasets:
            for dimension in dataset.dimensions:
                self._process(dimension)
