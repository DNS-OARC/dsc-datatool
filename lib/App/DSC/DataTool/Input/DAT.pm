package App::DSC::DataTool::Input::DAT;

use common::sense;
use Carp;

use base qw( App::DSC::DataTool::Input );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Input::DAT - DSC DAT input

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

DSC DAT input...

=head1 METHODS

=over 4

=item Init

Initialize the DAT input, called from the input factory.

=over 4

=item server

The server where the input comes from.

=item node

The node where the input comes from.

=item file

File to read input from.

=back

=cut

sub Init {
    my ( $self, %args ) = @_;

    foreach ( qw( server node file ) ) {
        unless ( $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
    }
    unless ( -r $self->{file} ) {
        croak 'file can not be read';
    }

    $self->{root}     = undef;
    $self->{datasets} = [];

    return $self;
}

=item Destroy

=cut

sub Destroy {
}

=item Name

=cut

sub Name {
    return 'DAT';
}

=item Dataset

=cut

sub Dataset {
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/DNS-OARC/dsc-datatool/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 OARC, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived
   from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut

1;    # End of App::DSC::DataTool::Input::DAT
