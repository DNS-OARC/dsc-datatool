# DSC DataTool

[![Build Status](https://travis-ci.com/DNS-OARC/dsc-datatool.svg?branch=develop)](https://travis-ci.com/DNS-OARC/dsc-datatool) [![Total alerts](https://img.shields.io/lgtm/alerts/g/DNS-OARC/dsc-datatool.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/DNS-OARC/dsc-datatool/alerts/) [![Bugs](https://sonarcloud.io/api/project_badges/measure?project=dns-oarc%3Adsc-datatool&metric=bugs)](https://sonarcloud.io/dashboard?id=dns-oarc%3Adsc-datatool) [![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=dns-oarc%3Adsc-datatool&metric=security_rating)](https://sonarcloud.io/dashboard?id=dns-oarc%3Adsc-datatool)

Tool for converting, exporting, merging and transforming DSC data.

Please have a look at [the wiki article](https://github.com/DNS-OARC/dsc-datatool/wiki/Setting-up-a-test-Grafana)
on how to set this up using Influx DB and Grafana.


## python

```
sudo apt-get install python3-maxminddb python3-yaml python3-venv
python3 -m venv venv --system-site-packages
. venv/bin/activate
pip install -e . --no-deps
```
