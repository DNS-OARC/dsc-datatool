"""dsc_datatool.input.xml

Input plugin to generate `Dataset`'s from DSC XML files.

Part of dsc_datatool.

:copyright: 2022 OARC, Inc.
"""

import logging
from xml.dom import minidom

from dsc_datatool import Input, Dataset, Dimension, process_dataset


class XML(Input):
    def process(self, file):
        dom = minidom.parse(file)
        datasets = []
        for array in dom.getElementsByTagName('array'):
            if process_dataset and not array.getAttribute('name') in process_dataset:
                continue

            dataset = Dataset()
            dataset.name = array.getAttribute('name')
            dataset.start_time = int(array.getAttribute('start_time'))
            dataset.stop_time = int(array.getAttribute('stop_time'))

            dimensions = [None, None]
            for dimension in array.getElementsByTagName('dimension'):
                if dimension.getAttribute('number') == '1':
                    if dimensions[0]:
                        logging.warning('Overwriting dimension 1 for %s' % dataset.name)
                    dimensions[0] = dimension.getAttribute('type')
                elif dimension.getAttribute('number') == '2':
                    if dimensions[1]:
                        logging.warning('Overwriting dimension 2 for %s' % dataset.name)
                    dimensions[1] = dimension.getAttribute('type')
                else:
                    logging.warning('Invalid dimension number %r for %s' % (dimension.getAttribute('number'), dataset.name))

            for node1 in array.getElementsByTagName(dimensions[0]):
                d1 = Dimension(dimensions[0])
                d1.value = node1.getAttribute('val')
                dataset.dimensions.append(d1)

                d2 = Dimension(dimensions[1])
                d1.dimensions.append(d2)
                for node2 in node1.getElementsByTagName(dimensions[1]):
                    d2.values[node2.getAttribute('val')] = int(node2.getAttribute('count'))

            datasets.append(dataset)

        return datasets


import sys
if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Input.__init_subclass__(XML)
