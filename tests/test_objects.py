import pytest
from dsc_datatool import Dataset, Dimension, Input, Output, Generator, Transformer


def test_dataset():
    o = Dataset()
    assert '%r' % o == '<Dataset name=None dimension=[]>'


def test_dimension():
    o = Dimension('test')
    assert '%r' % o == '<Dimension name=\'test\' value=None dimension=[]>'


def test_input():
    o = Input()
    with pytest.raises(Exception):
        o.process("test")

    class Input1(Input):
        def process(self, file):
            pass
    with pytest.raises(Exception):
        class Input1(Input):
            def process(self, file):
                pass


def test_output():
    o = Output({})
    with pytest.raises(Exception):
        o.process([])

    class Output1(Output):
        def process(self, file):
            pass
    with pytest.raises(Exception):
        class Output1(Output):
            def process(self, file):
                pass


def test_generator():
    o = Generator({})
    with pytest.raises(Exception):
        o.process([])

    class Generator1(Generator):
        def process(self, file):
            pass
    with pytest.raises(Exception):
        class Generator1(Generator):
            def process(self, file):
                pass


def test_transformer():
    o = Transformer({})
    with pytest.raises(Exception):
        o.process([])

    class Transformer1(Transformer):
        def process(self, file):
            pass
    with pytest.raises(Exception):
        class Transformer1(Transformer):
            def process(self, file):
                pass
