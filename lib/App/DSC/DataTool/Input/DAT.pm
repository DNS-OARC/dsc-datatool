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

=item directory

Directory to read files from.

=back

=cut

sub Init {
    my ( $self, %args ) = @_;

    foreach ( qw( server node directory ) ) {
        unless ( $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
    }
    unless ( -d $self->{directory} and -r $self->{directory} ) {
        croak 'directory can not be read';
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
    return 'DAT';
}

=item Dataset

=cut

my @dataset1d = qw(
  client_subnet_count
  ipv6_rsn_abusers_count
);

my %dataset2d = (
    qtype                => 'Qtype',
    rcode                => 'Rcode',
    do_bit               => 'D0',
    rd_bit               => 'RD',
    opcode               => 'Opcode',
    dnssec_qtype         => 'Qtype',
    edns_version         => 'EDNSVersion',
    client_subnet2_count => 'Class',
    client_subnet2_trace => 'Class',
    edns_bufsiz          => 'EDNSBufSiz',
    idn_qname            => 'IDNQname',
    client_port_range    => 'PortRange',
    priming_responses    => 'ReplyLen',
);

my %dataset3d = (
    chaos_types_and_names   => [ 'Qtype',         'Qname' ],
    certain_qnames_vs_qtype => [ 'CertainQnames', 'Qtype' ],
    direction_vs_ipproto    => [ 'Direction',     'IPProto' ],
    pcap_stats              => [ 'pcap_stat',     'ifname' ],
    transport_vs_qtype      => [ 'Transport',     'Qtype' ],
    dns_ip_version          => [ 'IPVersion',     'Qtype' ],
    priming_queries         => [ 'Transport',     'EDNSBufSiz' ],
    qr_aa_bits              => [ 'Direction',     'QRAABits' ],
);

sub Dataset {
    my ( $self ) = @_;

    unless ( exists $self->{datasets} ) {
        $self->{datasets} = [];

        foreach ( @dataset1d ) {
            $self->process1d( $self->{directory} . '/' . $_ . '.dat', $_ );
        }
        foreach ( keys %dataset2d ) {
            $self->process2d( $self->{directory} . '/' . $_ . '.dat', $_, $dataset2d{$_} );
        }
        foreach ( keys %dataset3d ) {
            $self->process3d( $self->{directory} . '/' . $_ . '.dat', $_, @{ $dataset3d{$_} } );
        }
    }

    return shift @{ $self->{datasets} };
}

=item process1d

=cut

sub process1d {
    my ( $self, $file, $name ) = @_;

    unless ( -r $file ) {
        return;
    }

    unless ( open( DAT, $file ) ) {
        $self->AddError(
            App::DSC::DataTool::Error->new(
                tag     => 'INVALID_DAT',
                args    => { file => $file },
                message => 'Unable to open DAT file ' . $file
            )
        );
        return;
    }

    while ( <DAT> ) {
        if ( /^#/o ) {
            next;
        }

        s/[\r\n]+$//o;
        my @dat        = split( /\s+/o );
        my $start_time = shift( @dat );

        my $dataset = App::DSC::DataTool::Dataset->new(
            name       => $name,
            server     => $self->{server},
            node       => $self->{node},
            start_time => $start_time,
            stop_time  => $start_time + 60,
        );

        unless ( scalar @dat == 1 ) {
            $self->AddError(
                App::DSC::DataTool::Error->new(
                    tag     => 'INVALID_DAT',
                    args    => { file => $file },
                    message => 'Invalid number of elements for a 1d dataset'
                )
            );

            close( DAT );

            return;
        }

        my $all = App::DSC::DataTool::Dataset::Dimension->new( name => 'All' );
        $all->AddValues( ALL => $dat[0] );
        $dataset->AddDimension( $all );

        push( @{ $self->{datasets} }, $dataset );
    }

    close( DAT );

    return;
}

=item process2d

=cut

sub process2d {
    my ( $self, $file, $name, $field ) = @_;

    unless ( -r $file ) {
        return;
    }

    unless ( open( DAT, $file ) ) {
        $self->AddError(
            App::DSC::DataTool::Error->new(
                tag     => 'INVALID_DAT',
                args    => { file => $file },
                message => 'Unable to open DAT file ' . $file
            )
        );
        return;
    }

    while ( <DAT> ) {
        if ( /^#/o ) {
            next;
        }

        s/[\r\n]+$//o;
        my @dat        = split( /\s+/o );
        my $start_time = shift( @dat );

        my $dataset = App::DSC::DataTool::Dataset->new(
            name       => $name,
            server     => $self->{server},
            node       => $self->{node},
            start_time => $start_time,
            stop_time  => $start_time + 60,
        );

        my $all = App::DSC::DataTool::Dataset::Dimension->new( name => 'All', value => 'ALL' );
        $dataset->AddDimension( $all );

        my $values = App::DSC::DataTool::Dataset::Dimension->new( name => $field );
        while ( scalar @dat ) {
            my $key   = shift( @dat );
            my $value = shift( @dat );

            unless ( defined $key and defined $value ) {
                $self->AddError(
                    App::DSC::DataTool::Error->new(
                        tag     => 'INVALID_DAT',
                        args    => { file => $file },
                        message => 'Invalid number of elements for a 2d dataset'
                    )
                );

                close( DAT );

                return;
            }

            $values->AddValues( $key => $value );
        }
        $all->AddDimension( $values );

        push( @{ $self->{datasets} }, $dataset );
    }

    close( DAT );

    return;
}

=item process3d

=cut

sub process3d {
    my ( $self, $file, $name, $first, $second ) = @_;

    unless ( -r $file ) {
        return;
    }

    unless ( open( DAT, $file ) ) {
        $self->AddError(
            App::DSC::DataTool::Error->new(
                tag     => 'INVALID_DAT',
                args    => { file => $file },
                message => 'Unable to open DAT file ' . $file
            )
        );
        return;
    }

    while ( <DAT> ) {
        if ( /^#/o ) {
            next;
        }

        s/[\r\n]+$//o;
        my @dat        = split( /\s+/o );
        my $start_time = shift( @dat );

        my $dataset = App::DSC::DataTool::Dataset->new(
            name       => $name,
            server     => $self->{server},
            node       => $self->{node},
            start_time => $start_time,
            stop_time  => $start_time + 60,
        );

        while ( scalar @dat ) {
            my $key   = shift( @dat );
            my $value = shift( @dat );

            unless ( defined $key and defined $value ) {
                $self->AddError(
                    App::DSC::DataTool::Error->new(
                        tag     => 'INVALID_DAT',
                        args    => { file => $file },
                        message => 'Invalid number of elements for a 3d dataset'
                    )
                );

                close( DAT );

                return;
            }

            my $first = App::DSC::DataTool::Dataset::Dimension->new( name => $first, value => $key );
            $dataset->AddDimension( $first );

            my @dat2 = split( /:/o, $value );
            my $values = App::DSC::DataTool::Dataset::Dimension->new( name => $second );
            while ( scalar @dat2 ) {
                my $key   = shift( @dat2 );
                my $value = shift( @dat2 );

                unless ( defined $key and defined $value ) {
                    $self->AddError(
                        App::DSC::DataTool::Error->new(
                            tag     => 'INVALID_DAT',
                            args    => { file => $file },
                            message => 'Invalid number of elements for a 3d dataset'
                        )
                    );

                    close( DAT );

                    return;
                }

                $values->AddValues( $key => $value );
            }
            $first->AddDimension( $values );
        }

        push( @{ $self->{datasets} }, $dataset );
    }

    close( DAT );

    return;
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

1;    # End of App::DSC::DataTool::Input::DAT
