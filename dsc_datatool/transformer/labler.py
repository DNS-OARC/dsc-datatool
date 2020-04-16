"""
    dsc_datatool
    ~~~~~~~~~~~~

    DSC datatool

    :copyright: 2020 OARC, Inc.
"""

import yaml

from dsc_datatool import Transformer


def _process(label, d):
    l = label.get(d.name, None)
    if d.values:
        if l is None:
            return

        values = d.values
        d.values = {}

        for k, v in values.items():
            nk = l.get(k, None)
            d.values[nk or k] = v

        return

    if l:
        v = l.get(d.value, None)
        if v:
            d.value = v
    for d2 in d.dimensions:
        _process(label, d2)


class Labler(Transformer):
    label = None

    def __init__(self, opts):
        if not 'yaml' in opts:
            raise Exception('yaml=file option required')
        f = open(opts.get('yaml'), 'r')
        self.label = yaml.load(f)
        f.close()

    def process(self, datasets):
        if self.label is None:
            return

        for dataset in datasets:
            label = self.label.get(dataset.name, None)
            if label is None:
                continue

            for d in dataset.dimensions:
                _process(label, d)