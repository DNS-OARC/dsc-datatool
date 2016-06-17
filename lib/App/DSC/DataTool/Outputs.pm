package App::DSC::DataTool::Outputs;

use common::sense;
use Carp;

use Module::Find;

our $INSTANCE;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Outputs - Output module factory

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Output module factory...

=head1 METHODS

=over 4

=item $instance = App::DSC::DataTool::Outputs->new (...)

Create a new output module factory object.

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        output => {},
    };
    bless $self, $class;

    foreach ( findsubmod App::DSC::DataTool::Output ) {
        eval 'require ' . $_ . ';';

        # TODO: log this?
        warn $@ if $@;

        unless ( $@ ) {
            $self->{output}->{ $_->Name } = $_;
        }
    }

    return $self;
}

=item $instance = App::DSC::DataTool::Outputs->instance

Return a singelton of the output module factory.

=cut

sub instance {
    return $INSTANCE ||= App::DSC::DataTool::Outputs->new;
}

=item $bool = $instance->Exists ( $name )

Return true(1) if an output module exists for the B<$name> otherwise false(0).

=cut

sub Exists {
    return $_[1] && $_[0]->{output}->{ $_[1] } ? 1 : 0;
}

=item $output = $instance->Output ( $name, ... )

Return a new output object for the specified B<$name> or undef if that name
does not exist.  Arguments after B<$name> will be given to the output modules
B<new> call.

=cut

sub Output {
    my ( $self, $name, %args ) = @_;

    return $name && $self->{output}->{$name}
      ? $self->{output}->{$name}->new( %args )
      : undef;
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

1;    # End of App::DSC::DataTool::Outputs
