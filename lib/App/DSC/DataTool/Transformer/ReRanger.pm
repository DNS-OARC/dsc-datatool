package App::DSC::DataTool::Transformer::ReRanger;

use common::sense;
use Carp;

use base qw( App::DSC::DataTool::Transformer );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Transformer::ReRanger - (Re)Group data according to ranges

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

(Re)Group data according to ranges...

=head1 METHODS

=over 4

=item Init

Initialize the transformer, called from the input factory.

=cut

sub Init {
    my ( $self, %args ) = @_;

    $args{key}                ||= 'mid';
    $args{func}               ||= 'sum';
    $args{pad_with}           ||= '0';
    $args{allow_invalid_keys} ||= 0;

    foreach ( qw( key func range ) ) {
        unless ( defined $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
    }
    foreach ( qw( pad_with pad_to allow_invalid_keys ) ) {
        if ( defined $args{$_} ) {
            $self->{$_} = $args{$_};
        }
    }

    if ( $self->{range} =~ /^\/(\d+)$/o ) {
        $self->{split_by} = $1;
    }
    else {
        croak 'invalid range: ' . $self->{range};
    }

    if ( $args{pad_to} ) {
        unless ( exists $args{pad_with} ) {
            croak 'pad_with is needed for pad_to';
        }
        unless ( length( $args{pad_with} ) == 1 ) {
            croak 'length of pad_with must be 1';
        }
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
    return 'ReRanger';
}

=item Dataset

=cut

sub Dataset {
    my ( $self, $dataset ) = @_;

    my @dimensions = $dataset->Dimensions;
    while ( my $dimension = shift( @dimensions ) ) {
        if ( $dimension->HaveValues ) {
            my ( %range, $low, $high, $nkey );

            my %value = $dimension->Values;
            foreach my $key ( keys %value ) {
                if ( $key =~ /^(\d+)$/o ) {
                    $low = $high = $1;
                }
                elsif ( $key =~ /^(\d+)-(\d+)$/o ) {
                    $low  = $1;
                    $high = $2;
                }
                elsif ( $key eq $self->{skipped_key} ) {
                    next;
                }
                elsif ( $key eq $self->{skipped_sum_key} ) {
                    $range{skipped} += $value{$key};
                    next;
                }
                else {
                    if ( $self->{allow_invalid_keys} ) {
                        $range{$key} = $value{$key};
                        next;
                    }
                    croak 'invalid key: ' . $key;
                }

                if ( $self->{key} eq 'low' ) {
                    $nkey = $low;
                }
                elsif ( $self->{key} eq 'mid' ) {
                    $nkey = $low + ( ( $high - $low ) / 2 );
                }
                elsif ( $self->{key} eq 'high' ) {
                    $nkey = $high;
                }
                else {
                    croak 'invalid key setting: ' . $self->{key};
                }

                if ( exists $self->{split_by} ) {
                    $nkey = int( $nkey / $self->{split_by} ) * $self->{split_by};
                    $low  = $nkey;
                    $high = $nkey + $self->{split_by} - 1;
                }
                else {
                    croak 'invalid range setting';
                }

                # Make sure Perl treats these as strings
                $low  .= '';
                $high .= '';
                $nkey .= '';

                if ( $self->{pad_to} ) {
                    if ( length( $low ) < $self->{pad_to} ) {
                        $low = ( $self->{pad_with} x ( $self->{pad_to} - length( $low ) ) ) . $low;
                    }
                    if ( length( $high ) < $self->{pad_to} ) {
                        $high = ( $self->{pad_with} x ( $self->{pad_to} - length( $high ) ) ) . $high;
                    }
                    if ( length( $nkey ) < $self->{pad_to} ) {
                        $nkey = ( $self->{pad_with} x ( $self->{pad_to} - length( $nkey ) ) ) . $nkey;
                    }
                }

                if ( $self->{func} eq 'sum' ) {
                    $range{ $low ne $high ? $low . '-' . $high : $nkey } += $value{$key};
                }
                else {
                    croak 'invalid func: ' . $self->{func};
                }
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

1;    # End of App::DSC::DataTool::Transformer::ReRanger
