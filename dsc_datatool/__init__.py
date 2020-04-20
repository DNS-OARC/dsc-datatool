"""
    dsc_datatool
    ~~~~~~~~~~~~

    DSC datatool

    :copyright: 2020 OARC, Inc.
"""

__version__ = '1.0.0'

import argparse
import logging
import os
import importlib
import pkgutil
import sys
import traceback
import re

args = argparse.Namespace()
inputs = {}
outputs = {}
generators = {}
transformers = {}
process_dataset = {}


class Dataset(object):
    name = None
    start_time = None
    stop_time = None
    dimensions = None

    def __init__(self):
        self.dimensions = []

    def __repr__(self):
        return '<Dataset name=%r dimension=%r>' % (self.name, self.dimensions)


class Dimension(object):
    name = None
    value = None
    values = None
    dimensions = None

    def __init__(self, name):
        self.name = name
        self.values = {}
        self.dimensions = []

    def __repr__(self):
        return '<Dimension name=%r value=%r dimension=%r>' % (self.name, self.values or self.value, self.dimensions)


class Input(object):
    def process(self, file):
        raise Exception('process() not overloaded')

    def __init_subclass__(cls):
        global inputs
        if cls.__name__ in inputs:
            raise Exception('Duplicate input module: %s already exists' % cls.__name__)
        inputs[cls.__name__] = cls


class Output(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global outputs
        if cls.__name__ in outputs:
            raise Exception('Duplicate output module: %s already exists' % cls.__name__)
        outputs[cls.__name__] = cls


class Generator(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global generators
        if cls.__name__ in generators:
            raise Exception('Duplicate generator module: %s already exists' % cls.__name__)
        generators[cls.__name__] = cls


class Transformer(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global transformers
        if cls.__name__ in transformers:
            raise Exception('Duplicate transformer module: %s already exists' % cls.__name__)
        transformers[cls.__name__] = cls


def main():
    def iter_namespace(ns_pkg):
        return pkgutil.iter_modules(ns_pkg.__path__, ns_pkg.__name__ + ".")


    def split_arg(arg, num=1):
        sep = arg[0]
        p = arg.split(sep)
        p.pop(0)
        ret = ()
        while num > 0:
            ret += (p.pop(0),)
            num -= 1
        ret += (p,)
        return ret


    def parse_opts(opts):
        ret = {}
        for opt in opts:
            p = opt.split('=', maxsplit=1)
            if len(p) > 1:
                if p[0] in ret:
                    if isinstance(ret[p[0]], list):
                        ret[p[0]].append(p[1])
                    else:
                        ret[p[0]] = [ ret[p[0]], p[1] ]
                else:
                    ret[p[0]] = p[1]
            elif len(p) > 0:
                ret[p[0]] = True
        return ret


    def _process(datasets, generators, transformers, outputs):
        gen_datasets = []
        for generator in generators:
            try:
                gen_datasets += generator.process(datasets)
            except Exception as e:
                logging.warning('Generator %s failed: %s' % (generator, e))
                exc_type, exc_value, exc_traceback = sys.exc_info()
                for tb in traceback.format_tb(exc_traceback):
                    logging.warning(str(tb))
                return 2

        datasets += gen_datasets

        if '*' in transformers:
            for transformer in transformers['*']:
                try:
                    transformer.process(datasets)
                except Exception as e:
                    logging.warning('Transformer %s failed: %s' % (transformer, e))
                    exc_type, exc_value, exc_traceback = sys.exc_info()
                    for tb in traceback.format_tb(exc_traceback):
                        logging.warning(str(tb))
                    return 2
        for dataset in datasets:
            if dataset.name in transformers:
                for transformer in transformers[dataset.name]:
                    try:
                        transformer.process([dataset])
                    except Exception as e:
                        logging.warning('Transformer %s failed: %s' % (transformer, e))
                        exc_type, exc_value, exc_traceback = sys.exc_info()
                        for tb in traceback.format_tb(exc_traceback):
                            logging.warning(str(tb))
                        return 2

        for output in outputs:
            try:
                output.process(datasets)
            except Exception as e:
                logging.warning('Output %s failed: %s' % (output, e))
                exc_type, exc_value, exc_traceback = sys.exc_info()
                for tb in traceback.format_tb(exc_traceback):
                    logging.warning(str(tb))
                return 2

        return 0


    global args, inputs, outputs, generators, transformers, process_dataset

    parser = argparse.ArgumentParser(prog='dsc-datatool',
        description='Export DSC data into various formats and databases.',
        epilog='See man-page dsc-datatool(1) and dsc-datatool-[generator|transformer|output] <name>(5) for more information')
    parser.add_argument('-c', '--conf', nargs=1,
        help='Not implemented')
    #    help='Specify the YAML configuration file to use (default to ~/.dsc-datatool.conf), any command line option will override the options in the configuration file. See dsc-datatool.conf(5)for more information.')
    parser.add_argument('-s', '--server', nargs=1,
        help='Specify the server for where the data comes from. (required)')
    parser.add_argument('-n', '--node', nargs=1,
        help='Specify the node for where the data comes from. (required)')
    parser.add_argument('-x', '--xml', action='append',
        help='Read DSC data from the given file or directory, can be specified multiple times. If a directory is given then all files ending with .xml will be read.')
    parser.add_argument('-d', '--dat', action='append',
        help='Read DSC data from the given directory, can be specified multiple times. Note that the DAT format is depended on the filename to know what type of data it is.')
    parser.add_argument('--dataset', action='append',
        help='Specify that only the list of datasets will be processed, the list is comma separated and the option can be given multiple times.')
    parser.add_argument('-o', '--output', action='append',
        help='"<sep><output>[<sep>option=value...]>" Output data to <output> and use <separator> as an options separator.')
    parser.add_argument('-t', '--transform', action='append',
        help='"<sep><name><sep><datasets>[<sep>option=value...]>" Use the transformer <name> to change the list of datasets in <datasets>.')
    parser.add_argument('-g', '--generator', action='append',
        help='"<name>[,<name>,...]" or "<sep><name>[<sep>option=value...]>" Use the specified generators to generate additional datasets.')
    parser.add_argument('--list', action='store_true',
        help='List the available generators, transformers and outputs then exit.')
    parser.add_argument('--skipped-key', nargs=1, default='-:SKIPPED:-',
        help='Set the special DSC skipped key. (default to "-:SKIPPED:-")')
    parser.add_argument('--skipped-sum-key', nargs=1, default='-:SKIPPED_SUM:-',
        help='Set the special DSC skipped sum key. (default to "-:SKIPPED_SUM:-")')
    parser.add_argument('-v', '--verbose', action='count', default=0,
        help='Increase the verbose level, can be given multiple times.')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s v'+__version__,
        help='Display version and exit.')

    args = parser.parse_args()

    log_level = 30 - (args.verbose * 10)
    if log_level < 0:
        log_level = 0
    logging.basicConfig(format='%(asctime)s %(levelname)s %(module)s: %(message)s', level=log_level, stream=sys.stderr)

    import dsc_datatool.input
    import dsc_datatool.output
    import dsc_datatool.generator
    import dsc_datatool.transformer

    for finder, name, ispkg in iter_namespace(dsc_datatool.input):
        importlib.import_module(name)
    for finder, name, ispkg in iter_namespace(dsc_datatool.output):
        importlib.import_module(name)
    for finder, name, ispkg in iter_namespace(dsc_datatool.generator):
        importlib.import_module(name)
    for finder, name, ispkg in iter_namespace(dsc_datatool.transformer):
        importlib.import_module(name)

    if args.list:
        print('Generators:')
        for name in generators:
            print('',name)
        print('Transformers:')
        for name in transformers:
            print('',name)
        print('Outputs:')
        for name in outputs:
            print('',name)
        return 0

    if not args.server or not args.node:
        raise Exception('--server and --node must be given')

    if isinstance(args.server, list):
        args.server = ' '.join(args.server)
    elif not isinstance(args.server, str):
        raise Exception('Invalid argument for --server: %r' % args.server)
    if isinstance(args.node, list):
        args.node = ' '.join(args.node)
    elif not isinstance(args.node, str):
        raise Exception('Invalid argument for --node: %r' % args.node)

    gens = []
    if args.generator:
        for arg in args.generator:
            if not re.match(r'^\w', arg):
                name, opts = split_arg(arg)
                if not name in generators:
                    logging.critical('Generator %s does not exist' % name)
                    return 1
                gens.append(generators[name](parse_opts(opts)))
                continue
            for name in arg.split(','):
                if not name in generators:
                    logging.critical('Generator %s does not exist' % name)
                    return 1
                gens.append(generators[name]({}))

    trans = {}
    if args.transform:
        for arg in args.transform:
            name, datasets, opts = split_arg(arg, num=2)
            if not name in transformers:
                logging.critical('Transformer %s does not exist' % name)
                return 1
            for dataset in datasets.split(','):
                if not dataset in trans:
                    trans[dataset] = []
                trans[dataset].append(transformers[name](parse_opts(opts)))

    out = []
    if args.output:
        for arg in args.output:
            name, opts = split_arg(arg)
            if not name in outputs:
                logging.critical('Output %s does not exist' % name)
                return 1
            out.append(outputs[name](parse_opts(opts)))

    if args.dataset:
        for dataset in args.dataset:
            for p in dataset.split(','):
                process_dataset[p] = True

    xml = []
    if args.xml:
        for entry in args.xml:
            if os.path.isfile(entry):
                xml.append(entry)
            elif os.path.isdir(entry):
                with os.scandir(entry) as dir:
                    for entry in dir:
                        if not entry.name.startswith('.') and entry.is_file() and entry.name.lower().endswith('.xml'):
                            xml.append(entry.path)
            else:
                logging.error('--xml %r is not a file or directory' % entry)

    dat = []
    if args.dat:
        for entry in args.dat:
            if os.path.isdir(entry):
                dat.append(entry)
            else:
                logging.error('--dat %r is not a directory' % entry)

    if not xml and not dat:
        logging.error('No valid --xml or --dat given')
        return 1

    xml_input = inputs['XML']()
    for file in xml:
        datasets = xml_input.process(file)

        ret = _process(datasets, gens, trans, out)
        if ret > 0:
            return ret

    dat_input = inputs['DAT']()
    for dir in dat:
        datasets = dat_input.process(dir)

        ret = _process(datasets, gens, trans, out)
        if ret > 0:
            return ret
