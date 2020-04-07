# DSC DataTool

[![Build Status](https://travis-ci.org/DNS-OARC/dsc-datatool.svg?branch=develop)](https://travis-ci.org/DNS-OARC/dsc-datatool)

Tool for converting, exporting, merging and transforming DSC data.

Please have a look at [the wiki article](https://github.com/DNS-OARC/dsc-datatool/wiki/Setting-up-a-test-Grafana)
on how to set this up using Influx DB and Grafana.


## python

```
sudo apt-get install python3-maxminddb python3-venv
python3 -m venv venv --system-site-packages
. venv/bin/activate
pip install -e .
```
