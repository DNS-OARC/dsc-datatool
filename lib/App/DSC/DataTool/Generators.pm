package App::DSC::DataTool::Generators;

use common::sense;
use Carp;

use Module::Find;

our $INSTANCE;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Generators - Generator module factory

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Generator module factory...

=head1 METHODS

=over 4

=item $generators = App::DSC::DataTool::Generators->new (...)

Create a new generator module factory object.

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        generator => {},
    };
    bless $self, $class;

    foreach ( findsubmod App::DSC::DataTool::Generator ) {
        eval 'require ' . $_ . ';';

        # TODO: log better
        if ( $@ ) {
            App::DSC::DataTool::Log->instance->log(
                'Generators',
                0,
                App::DSC::DataTool::Error->new(
                    reporter => $_,
                    tag      => 'REQUIRE_FAILED',
                    message  => $@
                )
            );
            next;
        }

        unless ( $@ ) {
            $self->{generator}->{ $_->Name } = $_;
        }
    }

    return $self;
}

=item $generators = App::DSC::DataTool::Generators->instance

Return a singelton of the generator module factory.

=cut

sub instance {
    return $INSTANCE ||= App::DSC::DataTool::Generators->new;
}

=item $bool = $generators->Exists ( $name )

Return true(1) if an generator module exists for the B<$name> otherwise
false(0).

=cut

sub Exists {
    return $_[1] && $_[0]->{generator}->{ $_[1] } ? 1 : 0;
}

=item @names = $generators->Have

Return an array of generator names that exists.

=cut

sub Have {
    return keys %{ $_[0]->{generator} };
}

=item $generator = $generators->Generator ( $name, ... )

Return a new generator object for the specified B<$name> or undef if that
name does not exist.  Arguments after B<$name> will be given to the
generator modules B<new> call.

=cut

sub Generator {
    my ( $self, $name, %args ) = @_;
    my $generator;

    if ( $name and $self->{generator}->{$name} ) {
        eval { $generator = $self->{generator}->{$name}->new( %args ); };

        # TODO: log better
        if ( $@ ) {
            App::DSC::DataTool::Log->instance->log(
                'Generators',
                0,
                App::DSC::DataTool::Error->new(
                    reporter => $self->{generator}->{$name},
                    tag      => 'NEW_FAILED',
                    message  => $@
                )
            );
            return;
        }
    }

    return $generator;
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

1;    # End of App::DSC::DataTool::Generators
