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


parser = argparse.ArgumentParser(prog='dsc-datatool', description='Export DSC data into various formats and databases.')
parser.add_argument('-c', '--conf', nargs=1)
# Specify the YAML configuration file to use (default to ~/.dsc-datatool.conf),
# any command line option will override the options in the configuration file.
# See B<dsc-datatool.conf(5)> for more information.
parser.add_argument('-s', '--server', nargs=1, required=True)
# Specify the server for where the data comes from.
parser.add_argument('-n', '--node', nargs=1, required=True)
# Specify the node for where the data comes from.
parser.add_argument('-x', '--xml', action='append')
# Read DSC data from the given file or directory, can be specified multiple
# times.
# If a directory is given then all files ending with B<.xml> will be read.
parser.add_argument('-d', '--dat', action='append')
# Read DSC data from the given directory, can be specified multiple
# times.
# Note that the DAT format is depended on the filename to know what type
# of data it is.
parser.add_argument('--dataset', action='append')
# Specify that only the list of datasets will be processed, the list is comma
# separated and the option can be given multiple times.
parser.add_argument('-o', '--output', action='append')
# =item B<[ -o | --output ] <sep><type>[<sep>option=value...]>
#
# Output data to B<type> and use B<separator> as an options separator, example:
#
#   --output ;Carbon;host=localhost;port=2003
#
# Can be specified multiple times to output to more then one.
#
# To see a full list of options, check the man-page of the output module:
  #
  # man App:DSC::DataTool::Output::NAME
parser.add_argument('-t', '--transform', action='append')
# =item B<[ -t | --transform ] <sep><type><sep><datasets>[<sep>option=value...]>
#
# Use the transformer B<type> to change the list of datasets in B<datasets>,
# example:
#
#   --transform ;ReRanger;rcode_vs_replylen;type=sum;range=/128
#
# B<datasets> is a comma separated list of datasets to run the tranformer on,
# because of this do not use comma (,) as a separator.  B<*> in B<datasets> will
# make the tranformer run on all datasets.
#
# Can be specific multiple times to chain transformation, the chain will be
# executed in the order on command line with one exception.  All transformations
# specified for dataset B<*> will be executed before named dataset
# transformations.
#
# To see a full list of options, check the man-page of the transformer module:
#
#   man App:DSC::DataTool::Transformer::NAME
#
# For a list of datasets see the DSC configuration that created the data files
# and the documentation for the Presenter.
parser.add_argument('-g', '--generator', action='append')
# =item B<[ -g | --generator ] <list of generators>>
#
# Use the specified generators to generate additional datasets, the list is comma
# separated and the option can be given multiple times.
#
parser.add_argument('--list', action='store_true')
# List the available B<inputs>, B<generators>, B<transformers> and B<outputs>.
parser.add_argument('--skipped-key', nargs=1, default='-:SKIPPED:-')
# Set the special DSC skipped key, default to "-:SKIPPED:-".
parser.add_argument('--skipped-sum-key', nargs=1, default='-:SKIPPED_SUM:-')
# Set the special DSC skipped sum key, default to "-:SKIPPED_SUM:-".
parser.add_argument('-v', '--verbose', action='count', default=0)
# Increase the verbose level, can be given multiple times.
parser.add_argument('-V', '--version', action='version', version='%(prog)s v'+__version__)
# Display version and exit.

args = parser.parse_args()


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


_inputs = {}
class Input(object):
    def process(self, file):
        raise Exception('process() not overloaded')

    def __init_subclass__(cls):
        global _inputs
        _inputs[cls.__name__] = cls


_outputs = {}
class Output(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global _outputs
        _outputs[cls.__name__] = cls


_generators = {}
class Generator(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global _generators
        _generators[cls.__name__] = cls


_transformers = {}
class Transformer(object):
    def process(self, datasets):
        raise Exception('process() not overloaded')

    def __init__(self, opts):
        pass

    def __init_subclass__(cls):
        global _transformers
        _transformers[cls.__name__] = cls


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


def main():
    global args, _inputs, _outputs, _generators, _transformers

    log_level = 30 - (args.verbose * 10)
    if log_level < 0:
        log_level = 0
    logging.basicConfig(format='%(asctime)s %(levelname)s %(module)s: %(message)s', level=log_level, stream=sys.stderr)

    generators = []
    if args.generator:
        for arg in args.generator:
            if not re.match(r'^\w', arg):
                name, opts = split_arg(arg)
                if not name in _generators:
                    logging.critical('Generator %s does not exist' % name)
                    return 1
                generators.append(_generators[name](parse_opts(opts)))
                continue
            for name in arg.split(','):
                if not name in _generators:
                    logging.critical('Generator %s does not exist' % name)
                    return 1
                generators.append(_generators[name]({}))

    transformers = {}
    if args.transform:
        for arg in args.transform:
            name, datasets, opts = split_arg(arg, num=2)
            if not name in _transformers:
                logging.critical('Transformer %s does not exist' % name)
                return 1
            for dataset in datasets.split(','):
                if not dataset in transformers:
                    transformers[dataset] = []
                transformers[dataset].append(_transformers[name](parse_opts(opts)))

    outputs = []
    if args.output:
        for arg in args.output:
            name, opts = split_arg(arg)
            if not name in _outputs:
                logging.critical('Output %s does not exist' % name)
                return 1
            outputs.append(_outputs[name](parse_opts(opts)))

    args.process_dataset = {}
    if args.dataset:
        for dataset in args.dataset:
            for p in dataset.split(','):
                args.process_dataset[p] = True

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

    xml_input = _inputs['XML']()
    for file in xml:
        datasets = xml_input.process(file)

        ret = _process(datasets, generators, transformers, outputs)
        if ret > 0:
            return ret

    dat_input = _inputs['DAT']()
    for dir in dat:
        datasets = dat_input.process(dir)

        ret = _process(datasets, generators, transformers, outputs)
        if ret > 0:
            return ret


def iter_namespace(ns_pkg):
    return pkgutil.iter_modules(ns_pkg.__path__, ns_pkg.__name__ + ".")

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
