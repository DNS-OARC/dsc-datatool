import pytest
import dsc_datatool as app


def test_main():
    with pytest.raises(Exception):
        app.main()
