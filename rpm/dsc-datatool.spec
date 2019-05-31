Name:           dsc-datatool
Version:        0.05
Release:        1%{?dist}
Summary:        Export DSC data to other formats and/or databases
Group:          Productivity/Networking/DNS/Utilities

License:        BSD-3-Clause
URL:            https://www.dns-oarc.net/oarc/data/dsc
# Using same naming as to build debs, get the source (and rename it) at
# https://www.dns-oarc.net/dsc/download and change %setup
Source0:        %{name}_%{version}.orig.tar.gz

BuildArch:      noarch

BuildRequires:  perl
%if 0%{?suse_version} || 0%{?sle_version}
BuildRequires:  perl-macros
%else
BuildRequires:  perl-macros
BuildRequires:  perl-generators
BuildRequires:  perl-interpreter
BuildRequires:  perl(ExtUtils::MakeMaker)
%endif
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::CheckManifest) >= 0.9
BuildRequires:  perl(common::sense) >= 3
BuildRequires:  perl(XML::LibXML::Simple) >= 0.93
BuildRequires:  perl(IO::Socket::INET) >= 1.31
BuildRequires:  perl(Time::HiRes)
BuildRequires:  perl(Getopt::Long)
BuildRequires:  perl(YAML::Tiny)
BuildRequires:  perl(Pod::Usage)
BuildRequires:  perl(Scalar::Util)
BuildRequires:  perl(Module::Find)
BuildRequires:  perl(NetAddr::IP)
BuildRequires:  perl(IP::Authority)
BuildRequires:  perl(IP::Country::Fast)

Provides:       perl(App::DSC::DataTool)

%description
Tool for converting, exporting, merging and transforming DSC data.


%prep
%setup -q -n %{name}_%{version}


%build
%if 0%{?suse_version} || 0%{?sle_version}
%{__perl} Makefile.PL
%else
%{__perl} Makefile.PL INSTALLDIRS=vendor
%endif
make %{?_smp_mflags}


%install
%if 0%{?suse_version} || 0%{?sle_version}
%perl_make_install
find %buildroot/%_prefix -name *.bs -a -size 0 | xargs rm -f
%perl_process_packlist
%perl_gen_filelist
%else
%{__make} pure_install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -delete
%{_fixperms} -c %{buildroot}
%endif


%clean
rm -rf $RPM_BUILD_ROOT


%if 0%{?suse_version} || 0%{?sle_version}
%files -f %{name}.files
%defattr(-,root,root)
%doc Changes LICENSE README.md
%else
%files
%license LICENSE
%doc Changes README.md
%{_bindir}/dsc-datatool
%{perl_vendorlib}/App/DSC/DataTool.pm
%{perl_vendorlib}/App/DSC/DataTool/
%{_mandir}/man1/dsc-datatool.1.gz
%{_mandir}/man3/App::DSC::DataTool.3*
%{_mandir}/man3/App::DSC::DataTool::Dataset.3*
%{_mandir}/man3/App::DSC::DataTool::Dataset::Dimension.3*
%{_mandir}/man3/App::DSC::DataTool::Error.3*
%{_mandir}/man3/App::DSC::DataTool::Errors.3*
%{_mandir}/man3/App::DSC::DataTool::Generator.3*
%{_mandir}/man3/App::DSC::DataTool::Generator::client_ports_count.3*
%{_mandir}/man3/App::DSC::DataTool::Generator::client_subnet_authority.3*
%{_mandir}/man3/App::DSC::DataTool::Generator::client_subnet_country.3*
%{_mandir}/man3/App::DSC::DataTool::Generators.3*
%{_mandir}/man3/App::DSC::DataTool::Input.3*
%{_mandir}/man3/App::DSC::DataTool::Input::DAT.3*
%{_mandir}/man3/App::DSC::DataTool::Input::XML.3*
%{_mandir}/man3/App::DSC::DataTool::Inputs.3*
%{_mandir}/man3/App::DSC::DataTool::Log.3*
%{_mandir}/man3/App::DSC::DataTool::Output.3*
%{_mandir}/man3/App::DSC::DataTool::Output::Carbon.3*
%{_mandir}/man3/App::DSC::DataTool::Output::InfluxDB.3*
%{_mandir}/man3/App::DSC::DataTool::Outputs.3*
%{_mandir}/man3/App::DSC::DataTool::Transformer.3*
%{_mandir}/man3/App::DSC::DataTool::Transformer::Labler.3*
%{_mandir}/man3/App::DSC::DataTool::Transformer::NetRemap.3*
%{_mandir}/man3/App::DSC::DataTool::Transformer::ReRanger.3*
%{_mandir}/man3/App::DSC::DataTool::Transformers.3*
%endif


%changelog
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
