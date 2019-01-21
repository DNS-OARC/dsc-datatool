package App::DSC::DataTool::Transformer::NetRemap;

use common::sense;
use Carp;

use NetAddr::IP ();

use base qw( App::DSC::DataTool::Transformer );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Transformer::NetRemap - (Re)Group data according to IP ranges

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

(Re)Group data according to IP ranges...

=head1 METHODS

=over 4

=item Init

Initialize the transformer, called from the input factory.

=cut

sub Init {
    my ( $self, %args ) = @_;

    $args{v4net} ||= $args{net};
    $args{v6net} ||= $args{net};

    foreach ( qw( v4net v6net ) ) {
        unless ( defined $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
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
    return 'NetRemap';
}

=item Dataset

=cut

sub Dataset {
    my ( $self, $dataset ) = @_;

    my @dimensions = $dataset->Dimensions;
    while ( my $dimension = shift( @dimensions ) ) {
        if ( $dimension->HaveValues ) {
            my ( %range, $ip );

            my %value = $dimension->Values;
            foreach my $key ( keys %value ) {
                if ( $key eq $self->{skipped_key} ) {
                    next;
                }
                if ( $key eq $self->{skipped_sum_key} ) {
                    $value{0} = $value{$key};
                    $key = 0;
                }

                unless ( ( $ip = NetAddr::IP->new( $key ) ) ) {
                    croak 'key is not an IP: ' . $key;
                }

                if ( $ip->version == 4 ) {
                    unless ( ( $ip = NetAddr::IP->new( $ip->addr . '/' . $self->{v4net} ) ) ) {
                        croak 'failed to remap net: ' . $key . '/' . $self->{v4net};
                    }
                }
                elsif ( $ip->version == 6 ) {
                    unless ( ( $ip = NetAddr::IP->new( $ip->addr . '/' . $self->{v6net} ) ) ) {
                        croak 'failed to remap net: ' . $key . '/' . $self->{v6net};
                    }
                }
                else {
                    croak 'no IP version';
                }

                $range{ $ip->network->addr } += $value{$key};
            }

            $dimension->SetValues( %range );
        }
        else {
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

1;    # End of App::DSC::DataTool::Transformer::NetRemap
