"""dsc_datatool.generator.client_subnet_country

See `man dsc-datatool-generator client_subnet_country`.

Part of dsc_datatool.

:copyright: 2020 OARC, Inc.
"""

import maxminddb
import os
import logging

from dsc_datatool import Generator, Dataset, Dimension, args


class client_subnet_country(Generator):
    reader = None
    nonstrict = False


    def __init__(self, opts):
        Generator.__init__(self, opts)
        paths = opts.get('path', ['/var/lib/GeoIP', '/usr/share/GeoIP', '/usr/local/share/GeoIP'])
        if not isinstance(paths, list):
            paths = [ paths ]
        filename = opts.get('filename', 'GeoLite2-Country.mmdb')
        db = opts.get('db', None)

        if db is None:
            for path in paths:
                db = '%s/%s' % (path, filename)
                if os.path.isfile(db) and os.access(db, os.R_OK):
                    break
                db = None
        if db is None:
            raise Exception('Please specify valid Maxmind database with path=,filename= or db=')

        logging.info('Using %s' % db)
        self.reader = maxminddb.open_database(db)

        if opts.get('nonstrict', False):
            self.nonstrict = True


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

            cc = {}
            for subnet in subnets:
                try:
                    c = self.reader.get(subnet)
                except Exception as e:
                    if not self.nonstrict:
                        raise e
                    continue
                if c:
                    iso_code = c.get('country', {}).get('iso_code', '??')
                    if iso_code in cc:
                        cc[iso_code] += subnets[subnet]
                    else:
                        cc[iso_code] = subnets[subnet]

            if cc:
                ccd = Dataset()
                ccd.name = 'client_subnet_country'
                ccd.start_time = dataset.start_time
                ccd.stop_time = dataset.stop_time
                gen_datasets.append(ccd)

                ccd1 = Dimension('ClientCountry')
                ccd1.values = cc
                ccd.dimensions.append(ccd1)

        return gen_datasets
