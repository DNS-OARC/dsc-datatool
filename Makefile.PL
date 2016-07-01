# Copyright (c) 2016, OARC, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::DSC::DataTool',
    DISTNAME      => 'p5-App-DSC-DataTool',
    AUTHOR        => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM  => 'lib/App/DSC/DataTool.pm',
    ABSTRACT      => 'Export DSC data to other formats and/or databases',
    EXE_FILES     => ['bin/dsc-datatool'],
    (
        !eval { ExtUtils::MakeMaker->VERSION( 6.3002 ) }
        ? ()
        : ( LICENSE => 'bsd' )
    ),
    (
        eval { ExtUtils::MakeMaker->VERSION( 6.5503 ) }
        ? (
            BUILD_REQUIRES => {
                'Test::More'          => 0,
                'Test::CheckManifest' => 0.9,
                'common::sense'       => 3,
                'XML::LibXML::Simple' => 0.93,
                'IO::Socket::INET'    => 1.31,
                'Time::HiRes'         => 0,
                'Getopt::Long'        => 0,
                'YAML::Tiny'          => 0,
                'Pod::Usage'          => 0,
                'Scalar::Util'        => 0,
                'Module::Find'        => 0,
            },
            PREREQ_PM => {
                'common::sense'       => 3,
                'XML::LibXML::Simple' => 0.93,
                'IO::Socket::INET'    => 1.31,
                'Time::HiRes'         => 0,
                'Getopt::Long'        => 0,
                'YAML::Tiny'          => 0,
                'Pod::Usage'          => 0,
                'Scalar::Util'        => 0,
                'Module::Find'        => 0,
            }
          )
        : (
            PREREQ_PM => {
                'Test::More'          => 0,
                'common::sense'       => 3,
                'XML::LibXML::Simple' => 0.93,
                'IO::Socket::INET'    => 1.31,
                'Time::HiRes'         => 0,
                'Getopt::Long'        => 0,
                'YAML::Tiny'          => 0,
                'Pod::Usage'          => 0,
                'Scalar::Util'        => 0,
                'Module::Find'        => 0,
            }
        )
    ),
    (
        !eval { ExtUtils::MakeMaker->VERSION( 6.46 ) }
        ? ()
        : (
            META_ADD => {
                resources => {
                    homepage   => 'https://github.com/DNS-OARC/dsc-datatool',
                    repository => 'https://github.com/DNS-OARC/dsc-datatool',
                    bugtracker => 'https://github.com/DNS-OARC/dsc-datatool/issues',
                },
            }
        )
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'p5-App-DSC-DataTool-*' },
);
