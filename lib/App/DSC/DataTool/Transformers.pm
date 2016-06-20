package App::DSC::DataTool::Transformers;

use common::sense;
use Carp;

use Module::Find;

our $INSTANCE;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Transformers - Transformer module factory

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Transformer module factory...

=head1 METHODS

=over 4

=item $transformers = App::DSC::DataTool::Transformers->new (...)

Create a new transformer module factory object.

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        transformer => {},
    };
    bless $self, $class;

    foreach ( findsubmod App::DSC::DataTool::Transformer ) {
        eval 'require ' . $_ . ';';

        # TODO: log better
        if ( $@ ) {
            App::DSC::DataTool::Log->instance->log(
                'Transformers',
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
            $self->{transformer}->{ $_->Name } = $_;
        }
    }

    return $self;
}

=item $transformers = App::DSC::DataTool::Transformers->instance

Return a singelton of the transformer module factory.

=cut

sub instance {
    return $INSTANCE ||= App::DSC::DataTool::Transformers->new;
}

=item $bool = $transformers->Exists ( $name )

Return true(1) if an transformer module exists for the B<$name> otherwise
false(0).

=cut

sub Exists {
    return $_[1] && $_[0]->{transformer}->{ $_[1] } ? 1 : 0;
}

=item $transformer = $transformers->Transformer ( $name, ... )

Return a new transformer object for the specified B<$name> or undef if that
name does not exist.  Arguments after B<$name> will be given to the
transformer modules B<new> call.

=cut

sub Transformer {
    my ( $self, $name, %args ) = @_;
    my $transformer;

    if ( $name and $self->{transformer}->{$name} ) {
        eval { $transformer = $self->{transformer}->{$name}->new( %args ); };

        # TODO: log better
        if ( $@ ) {
            App::DSC::DataTool::Log->instance->log(
                'Transformers',
                0,
                App::DSC::DataTool::Error->new(
                    reporter => $self->{transformer}->{$name},
                    tag      => 'NEW_FAILED',
                    message  => $@
                )
            );
            return;
        }
    }

    return $transformer;
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

1;    # End of App::DSC::DataTool::Transformers
