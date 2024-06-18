"""dsc_datatool.input.xml

Input plugin to generate `Dataset`'s from DSC XML files.

Part of dsc_datatool.

:copyright: 2024 OARC, Inc.
"""

import logging
from xml.dom import minidom
import base64

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
                try:
                    if node1.getAttribute('base64'):
                        d1.value = base64.b64decode(d1.value).decode('utf-8')
                except Exception as e:
                    pass
                dataset.dimensions.append(d1)

                d2 = Dimension(dimensions[1])
                d1.dimensions.append(d2)
                for node2 in node1.getElementsByTagName(dimensions[1]):
                    val = node2.getAttribute('val')
                    try:
                        if node2.getAttribute('base64'):
                            val = base64.b64decode(val).decode('utf-8')
                    except Exception as e:
                        pass
                    d2.values[val] = int(node2.getAttribute('count'))

            datasets.append(dataset)

        return datasets


import sys
if sys.version_info[0] == 3 and sys.version_info[1] == 5: # pragma: no cover
    Input.__init_subclass__(XML)
