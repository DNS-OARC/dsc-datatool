# DSC DataTool

[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=dns-oarc%3Adsc-datatool&metric=bugs)](https://sonarcloud.io/summary/new_code?id=dns-oarc%3Adsc-datatool) [![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=dns-oarc%3Adsc-datatool&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=dns-oarc%3Adsc-datatool)

Tool for converting, exporting, merging and transforming DSC data.

Please have a look at the man-page(s) `dsc-datatool` (1) on how to use or
[the wiki article](https://codeberg.org/DNS-OARC/dsc-datatool/wiki/Setting-up-a-test-Grafana)
on how to set this up using Influx DB and Grafana.

More information about DSC may be found here:
- https://www.dns-oarc.net/tools/dsc
- https://www.dns-oarc.net/oarc/data/dsc

Issues should be reported here:
- https://codeberg.org/DNS-OARC/dsc-datatool/issues

General support and discussion:
- Mattermost: https://chat.dns-oarc.net/community/channels/oarc-software

## Dependencies

`dsc-datatool` requires the following Python libraries:
- PyYAML
- maxminddb

## Python Development Environment

Using Ubuntu/Debian:

```
sudo apt-get install python3-maxminddb python3-yaml python3-venv
python3 -m venv venv --system-site-packages
. venv/bin/activate
pip install -e . --no-deps
```
