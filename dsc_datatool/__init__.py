"""dsc_datatool

The main Python module for the command line tool `dsc-datatool`, see
`man dsc-datatool` on how to run it.

On runtime it will load all plugins under the following module path:
- dsc_datatool.input
- dsc_datatool.output
- dsc_datatool.generator
- dsc_datatool.transformer

Each plugin category should base it class on one of the follow superclasses:
- dsc_datatool.Input
- dsc_datatool.Output
- dsc_datatool.Generator
- dsc_datatool.Transformer

Doing so it will be automatically registered as available and indexed in
the following public dicts using the class name:
- inputs
- outputs
- generators
- transformers

Example of an output:

    from dsc_datatool import Output
    class ExampleOutput(Output):
        def process(self, datasets)
            ...

:copyright: 2020 OARC, Inc.
"""

__version__ = '1.0.2'

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
    """A representation of a DSC dataset

    A DSC dataset is one to two dimensional structure where the last
    dimension holds an array of values and counters.

    It is based on the XML structure of DSC:

        <array name="pcap_stats" dimensions="2" start_time="1563520560" stop_time="1563520620">
          <dimension number="1" type="ifname"/>
          <dimension number="2" type="pcap_stat"/>
          <data>
            <ifname val="eth0">
              <pcap_stat val="filter_received" count="5625"/>
              <pcap_stat val="pkts_captured" count="4894"/>
              <pcap_stat val="kernel_dropped" count="731"/>
            </ifname>
          </data>
        </array>

    Attributes:
    - name: The name of the dataset
    - start_time: The start time of the dataset in seconds
    - stop_time: The stop time of the dataset in seconds
    - dimensions: An array with `Dimension`, the first dimension
    """
    name = None
    start_time = None
    stop_time = None
    dimensions = None


    def __init__(self):
        self.dimensions = []


    def __repr__(self):
        return '<Dataset name=%r dimension=%r>' % (self.name, self.dimensions)


class Dimension(object):
    """A representation of a DSC dimension

    A DSC dataset dimension which can be the first or second dimension,
    see `Dataset` for more information.

    Attributes:
    - name: The name of the dimension
    - value: Is set to the value of the dimension if it's the first dimension
    - values: A dict of values with corresponding counters if it's the second dimension
    """
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
    """Base class of an input plugin"""


    def process(self, file):
        """Input.process(...) -> [ Dataset, ... ]

        Called to process a file and return an array of `Dataset`'s found in it.
        """
        raise Exception('process() not overloaded')


    def __init_subclass__(cls):
        """This method is called when a class is subclassed and it will
        register the input plugin in `inputs`."""
        global inputs
        if cls.__name__ in inputs:
            raise Exception('Duplicate input module: %s already exists' % cls.__name__)
        inputs[cls.__name__] = cls


class Output(object):
    """Base class of an output plugin"""


    def process(self, datasets):
        """Output.process([ Dataset, ... ])

        Called to output the `Dataset`'s in the given array."""
        raise Exception('process() not overloaded')


    def __init__(self, opts):
        """instance = Output({ 'opt': value, ... })

        Called to create an instance of the output plugin, will get a dict
        with options provided on command line."""
        pass


    def __init_subclass__(cls):
        """This method is called when a class is subclassed and it will
        register the output plugin in `outputs`."""
        global outputs
        if cls.__name__ in outputs:
            raise Exception('Duplicate output module: %s already exists' % cls.__name__)
        outputs[cls.__name__] = cls


class Generator(object):
    """Base class of a generator plugin"""


    def process(self, datasets):
        """Generator.process([ Dataset, ... ]) -> [ Dataset, ... ]

        Called to generate additional `Dataset`'s based on the given array
        of `Dataset`'s."""
        raise Exception('process() not overloaded')


    def __init__(self, opts):
        """instance = Generator({ 'opt': value, ... })

        Called to create an instance of the generator plugin, will get a dict
        with options provided on command line."""
        pass


    def __init_subclass__(cls):
        """This method is called when a class is subclassed and it will
        register the generator plugin in `generators`."""
        global generators
        if cls.__name__ in generators:
            raise Exception('Duplicate generator module: %s already exists' % cls.__name__)
        generators[cls.__name__] = cls


class Transformer(object):
    """Base class of a transformer plugin"""


    def process(self, datasets):
        """Transformer.process([ Dataset, ... ])

        Called to do transformation of the given `Dataset`'s, as in modifying
        them directly."""
        raise Exception('process() not overloaded')


    def __init__(self, opts):
        """instance = Transformer({ 'opt': value, ... })

        Called to create an instance of the transformer plugin, will get a dict
        with options provided on command line."""
        pass


    def __init_subclass__(cls):
        """This method is called when a class is subclassed and it will
        register the transformer plugin in `transformers`."""
        global transformers
        if cls.__name__ in transformers:
            raise Exception('Duplicate transformer module: %s already exists' % cls.__name__)
        transformers[cls.__name__] = cls


def main():
    """Called when running `dsc-datatool`."""
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
                    for file in dir:
                        if not file.name.startswith('.') and file.is_file() and file.name.lower().endswith('.xml'):
                            xml.append(file.path)
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
        try:
            datasets = xml_input.process(file)
        except Exception as e:
            logging.critical('Unable to process XML file %s: %s' % (file, e))
            return 1

        ret = _process(datasets, gens, trans, out)
        if ret > 0:
            return ret

    dat_input = inputs['DAT']()
    for dir in dat:
        try:
            datasets = dat_input.process(dir)
        except Exception as e:
            logging.critical('Unable to process DAT files in %s: %s' % (dir, e))
            return 1

        ret = _process(datasets, gens, trans, out)
        if ret > 0:
            return ret
