Name:           dsc-datatool
Version:        1.4.0
Release:        1%{?dist}
Summary:        Export DSC data to other formats and/or databases
Group:          Productivity/Networking/DNS/Utilities

License:        BSD-3-Clause
URL:            https://www.dns-oarc.net/oarc/data/dsc
# Source needs to be generated by dist-tools/create-source-packages, see
# https://github.com/jelu/dist-tools
Source0:        https://github.com/DNS-OARC/dsc-datatool/archive/v%{version}.tar.gz?/%{name}_%{version}.orig.tar.gz

BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python-rpm-macros
%if 0%{?el7}
BuildRequires:  python36-maxminddb
BuildRequires:  python36-PyYAML
%else
BuildRequires:  python3-maxminddb
BuildRequires:  python3-PyYAML
%endif

%if 0%{?el7}
Requires:       python36-maxminddb
Requires:       python36-PyYAML
%else
Requires:       python3-maxminddb
Requires:       python3-PyYAML
%endif

%package doc
Summary:        Documentation files for %{name}
Group:          Documentation


%description
Tool for converting, exporting, merging and transforming DSC data.


%description doc
Tool for converting, exporting, merging and transforming DSC data.

This package contains the documentation for dsc-datatool.


%prep
%setup -q -n %{name}_%{version}


%build
python3 setup.py build


%install
python3 setup.py install --prefix=%{_prefix} --root=%{buildroot}
mkdir -p %{buildroot}%{_mandir}/man1/
install -m644 man/man1/dsc-datatool.1 %{buildroot}%{_mandir}/man1/
mkdir -p %{buildroot}%{_mandir}/man5/
install -m644 man/man5/dsc-datatool.conf.5 %{buildroot}%{_mandir}/man5/
mkdir -p %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-transformer-reranger.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-generator-client_subnet_country.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-generator-client_subnet_authority.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-output-influxdb.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-output-prometheus.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-transformer-labler.7 %{buildroot}%{_mandir}/man7/
install -m644 man/man7/dsc-datatool-transformer-netremap.7 %{buildroot}%{_mandir}/man7/


%files
%license LICENSE
%{_bindir}/dsc-datatool
%{_mandir}/man1/dsc-datatool.1*
%{_mandir}/man5/dsc-datatool.conf.5*
%{_mandir}/man7/dsc-datatool*.7*
%{python3_sitelib}/dsc_datatool*


%files doc
%doc CHANGES README.md
%license LICENSE


%changelog
* Thu Jun 15 2023 Jerry Lundström <lundstrom.jerry@gmail.com> 1.4.0-1
- Release 1.4.0
  * This release adds the option `--encoding` to set an encoding to use
    for reading and writing files.
  * Commits:
    f64c8b6 encoding man-page
    09c0ce9 Encoding
* Thu Nov 10 2022 Jerry Lundström <lundstrom.jerry@gmail.com> 1.3.0-1
- Release 1.3.0
  * This release adds option `nonstrict` to `client_subnet_authority`
    generator for skipping bad data in datasets.
  * The contrib DSC+Grafana test site dashboards has been moved to its
    own repository, feel free to contribute your own creations to it:
      https://github.com/DNS-OARC/dsc-datatool-grafana
  * Commits:
    90b232d Add CodeQL workflow for GitHub code scanning
    e4fa3b0 Test site
    474f97d client_subnet_authority non-strict mode
* Mon Jun 13 2022 Jerry Lundström <lundstrom.jerry@gmail.com> 1.2.0-1
- Release 1.2.0
  * This release fixes handling of base64'ed strings in DSC XML and will
    now decode them back into text when reading, the selected output will
    then handling any quoting or escaping needed.
  * Added a new option for Prometheus output to set a prefix for metrics so
    that they can be easily separated from other metrics if needed, see
    `man dsc-datatool-output prometheus`.
  * Commits:
    5f9f972 Fix COPR
    3d72019 Prometheus metric prefix
    bdc992e base64 labels
* Tue Apr 05 2022 Jerry Lundström <lundstrom.jerry@gmail.com> 1.1.0-1
- Release 1.1.0
  * This releases adds support for Prometheus' node_exporter using it's
    Textfile Collector (see `man dsc-datatool-output prometheus`) and
    fixes a bug in InfluxDB output when selecting what timestamp to use.
    Also updates packages and Grafana test site dashboards.
  * Commits:
    4381541 RPM
    19bc153 Typo/clarification
    2a32dd8 Prometheus, InfluxDB, Copyright
    dd5323e debhelper
    7352c1e Bye Travis
    32b3bbe Grafana dashboards
    304ab76 Info
* Wed Oct 21 2020 Jerry Lundström <lundstrom.jerry@gmail.com> 1.0.2-1
- Release 1.0.2
  * This release fixed a bug in DAT file parsing that was discovered when
    adding coverage tests.
  * Commits:
    45b1aa3 Coverage
    7aedc1a Coverage
    64957b9 DAT, Coverage
    370fb86 Coverage
    891cb7c Coverage
    9374faa Coverage
* Fri Aug 07 2020 Jerry Lundström <lundstrom.jerry@gmail.com> 1.0.1-1
- Release 1.0.1
  * This release adds compatibility with Python v3.5 which allows
    packages to be built for Ubuntu Xenial.
  * Commits:
    bc0be5b python 3.5
* Mon Aug 03 2020 Jerry Lundström <lundstrom.jerry@gmail.com> 1.0.0-2
- Release 1.0.0
  * This release brings a complete rewrite of the tool, from Perl to
    Python. This rewrite was made possible thanks to funding from EURid,
    and will help with maintainability and packaging.
  * Core design and command line syntax is kept the same but as the
    libraries the generators use have been changed additional command line
    options must be used.
    - client_subnet_authority (generator)
      This generator now uses IANA's IP address space registry CSVs to
      look up the network authority, therefor it needs either to fetch
      the CSV files or be given them on command line.
      See `man dsc-datatool-generator client_subnet_authority` for more
      information.
    - client_subnet_country (generator)
      This generator now uses MaxMind databases to look up country based
      on subnet.
      See `man dsc-datatool generator client_subnet_country` for more
      information and setup guide of the MaxMind databases.
  * Commits:
    589ea8b Badges
    c32038b nonstrict
    0ea3e32 LGTM
    cff2e1c COPR
    02c31b0 COPR
    e8332fd COPR
    6d9f71c Input, YAML
    93ba755 EPEL 8 packages
    3e2df6f Authority
    f5d023f Debian packaging
    1a59f09 Documentation
    85cb1e1 restructure
    decd3f6 man-pages, URLs
    f264854 man-pages
    d73c319 man-pages
    f5ca007 man-pages
    7bfaf53 Fedora dependencies
    3452b48 RPM dependencies
    7a4edbc Test
    ed43406 client_subnet_authority
    62c7d9d Server, node
    e0c6419 RPM package
    938f154 Rewrite
    5400464 README
    968ccb1 COPR, spec
    14d987f RPM requires
    ee10efb Package
    a25870f Funding
* Wed Apr 15 2020 Jerry Lundström <lundstrom.jerry@gmail.com> 1.0.0-1
- Prepare for v1.0.0
* Fri May 31 2019 Jerry Lundström <lundstrom.jerry@gmail.com> 0.05-1
- Release 0.05
  * Fixed issue with empty values in InfluxDB output, they are now
    quoted as an empty string.
  * Commits:
    9917c4e InfluxDB quote keys/values
* Mon Jan 21 2019 Jerry Lundström <lundstrom.jerry@gmail.com> 0.04-1
- Release 0.04
  * Package dependency fix and update of example Grafana dashboards.
  * Commits:
    d3babc9 Copyright years
    9955c88 Travis Perl versions
    134a8b3 Debian dependency
    2d2114d Fix #23: Rework Grafana dashboards to hopefully show more
            correct numbers and also split them up.
    9bca0d3 Prepare SPEC for OSB/COPR
* Fri Dec 16 2016 Jerry Lundström <lundstrom.jerry@gmail.com> 0.03-1
- Release 0.03
  * Support processing of 25 of the 37 DAT files that the Extractor
    can produce, the others can not be converted into time series data
    since they lack timestamps.  Processing of XML is the recommended
    approach to secure all information.
  * Commits:
    72e829c Implement processing of DAT directories
    45294d0 RPM spec
    4e8ff69 Fix 5.24 forbidden keys usage
    7589ad2 Use perl 5.24 also
    cfac110 Fix #16: Handle directories in --xml and warn that --dat is
            not implemented yet
* Thu Dec 15 2016 Jerry Lundström <lundstrom.jerry@gmail.com> 0.02-1
- Initial package
