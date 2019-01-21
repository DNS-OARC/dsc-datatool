package App::DSC::DataTool::Transformer::Labler;

use common::sense;
use Carp;

use YAML::Tiny;
use App::DSC::DataTool::Log;
use App::DSC::DataTool::Error;

use base qw( App::DSC::DataTool::Transformer );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Transformer::Labler - Set/change labels on dimensions

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Set/change labels on dimensions...

=head1 METHODS

=over 4

=item Init

Initialize the transformer, called from the input factory.

#TODO: documentation

=cut

sub Init {
    my ( $self, %args ) = @_;

    foreach ( qw( yaml ) ) {
        unless ( defined $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
    }

    my $yaml = YAML::Tiny->new;
    unless ( ( $self->{label} = $yaml->read( $self->{yaml} ) ) ) {
        App::DSC::DataTool::Log->instance->log(
            'Labler',
            0,
            App::DSC::DataTool::Error->new(
                reporter => $self,
                tag      => 'YAML_LOAD',
                message  => $yaml->errstr
            )
        );
    }

    $self->{label} = $self->{label}->[0];

    if ( defined $self->{label} and ref( $self->{label} ) ne 'HASH' ) {
        App::DSC::DataTool::Log->instance->log(
            'Labler',
            0,
            App::DSC::DataTool::Error->new(
                reporter => $self,
                tag      => 'YAML',
                message  => 'YAML is invalid, must be a HASH'
            )
        );
        delete $self->{label};
    }

    return $self;
}

=item Destroy

=cut

sub Destroy {
}

=item Name

=cut

sub Name {
    return 'Labler';
}

=item Dataset

=cut

sub Dataset {
    my ( $self, $dataset ) = @_;

    unless ( $self->{label} ) {
        return;
    }
    unless ( $self->{label}->{ $dataset->Name } ) {
        return;
    }

    my @dimensions = $dataset->Dimensions;
    while ( my $dimension = shift( @dimensions ) ) {
        my $label = $self->{label}->{ $dataset->Name }->{ $dimension->Name };
        if ( $dimension->HaveValues ) {
            unless ( $label ) {
                next;
            }

            my %value = $dimension->Values;
            my %new_value;

            foreach my $key ( keys %value ) {
                $new_value{ exists $label->{$key} ? $label->{$key} : $key } = $value{$key};
            }

            $dimension->SetValues( %new_value );
        }
        else {
            if ( $label and exists $label->{ $dimension->Value } ) {
                $dimension->SetValue( $label->{ $dimension->Value } );
            }

            push( @dimensions, $dimension->Dimensions );
        }
    }

    return $dataset;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/DNS-OARC/dsc-datatool/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2019 OARC, Inc.
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

1;    # End of App::DSC::DataTool::Transformer::Labler
