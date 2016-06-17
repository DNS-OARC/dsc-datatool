package App::DSC::DataTool::Input::XML;

use common::sense;
use Carp;

use base qw( App::DSC::DataTool::Input );

use App::DSC::DataTool::Error;
use App::DSC::DataTool::Dataset;
use App::DSC::DataTool::Dataset::Dimension;

use XML::LibXML::Simple qw( XMLin );

my %metric = (
    certain_qnames_vs_qtype => 0,
    chaos_types_and_names   => 0,
    client_addr_vs_rcode    => 0,
    client_port_range       => 0,
    client_subnet           => 0,
    client_subnet2          => 0,
    direction_vs_ipproto    => 1,
    do_bit                  => 1,
    edns_bufsiz             => 1,
    edns_version            => 1,
    idn_qname               => 0,
    idn_vs_tld              => 0,
    ipv6_rsn_abusers        => 0,
    opcode                  => 1,
    pcap_stats              => 1,
    qtype                   => 1,
    qtype_vs_qnamelen       => 0,
    qtype_vs_tld            => 0,
    rcode                   => 1,
    rcode_vs_replylen       => 0,
    rd_bit                  => 1,
    transport_vs_qtype      => 1,
);

=encoding utf8

=head1 NAME

App::DSC::DataTool::Input::XML - DSC XML input

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

DSC XML input...

=head1 METHODS

=over 4

=item Init

=over 4

=item file

File to read input from.

=back

=cut

sub Init {
    my ( $self, %args ) = @_;

    unless ( $args{file} ) {
        confess 'file must be given';
    }
    unless ( -r $args{file} ) {
        confess 'file can not be read';
    }
    $self->{file} = $args{file};

    $self->{root}     = undef;
    $self->{datasets} = [];
}

=item Destroy

=cut

sub Destroy {
}

=item Name

=cut

sub Name {
    return 'XML';
}

=item Dataset

=cut

sub Dataset {
    my ( $self ) = @_;

    unless ( $self->{root} ) {
        my $root = XMLin( $self->{file} );

        unless (ref( $root ) eq 'HASH'
            and ref( $root->{array} ) eq 'HASH' )
        {
            $self->AddError(
                App::DSC::DataTool::Error->new(
                    tag     => 'INVALID_XML',
                    args    => { file => $self->{file} },
                    message => 'Invalid XML in file ' . $self->{file}
                )
            );
            return;
        }

        if ( exists $root->{array}->{name} ) {
            my $name = delete $root->{array}->{name};

            $root->{array} = { $name => $root->{array} };
        }

        foreach my $name ( keys %{ $root->{array} } ) {
            my $metric = $root->{array}->{$name};

            next unless ( $metric{$name} );

            unless (ref( $metric ) eq 'HASH'
                and $metric->{start_time}
                and ref( $metric->{data} ) eq 'HASH'
                and ref( $metric->{dimension} ) eq 'ARRAY' )
            {
                $self->AddError(
                    App::DSC::DataTool::Error->new(
                        tag     => 'INVALID_METRIC',
                        args    => { name => $name },
                        message => 'Invalid metric for ' . $name
                    )
                );
                next;
            }

            my $invalid_dimension = 0;
            foreach ( @{ $metric->{dimension} } ) {
                unless (ref( $_ ) eq 'HASH'
                    and $_->{number}
                    and $_->{type} )
                {
                    $invalid_dimension = 1;
                }
            }
            if ( $invalid_dimension ) {
                $self->AddError(
                    App::DSC::DataTool::Error->new(
                        tag     => 'INVALID_DIMENSIONS',
                        args    => { name => $name },
                        message => 'Invalid dimenions for ' . $name
                    )
                );
                next;
            }

            my $dataset = App::DSC::DataTool::Dataset->new(
                name       => $name,
                start_time => $metric->{start_time},
                stop_time  => $metric->{stop_time}
            );

            my @dimensions;
            my $previous = $dataset;
            foreach my $dimension ( sort { $a->{number} <=> $b->{number} } ( @{ $metric->{dimension} } ) ) {
                my $obj = App::DSC::DataTool::Dataset::Dimension->new( name => $dimension->{type} );
                $previous->AddDimension( $obj );
                $dimension->{obj} = $obj;
                push( @dimensions, $dimension );
                $previous = $obj;
            }

            $self->Process( $name, $metric->{data}, \@dimensions, 0 );
            push( @{ $self->{datasets} }, $dataset );
        }

        $self->{root} = $root;
    }

    return shift @{ $self->{datasets} };
}

=back

=head1 PRIVATE METHODS

=over 4

=item Process

=cut

sub Process {
    my ( $self, $name, $data, $dimension, $position ) = @_;

    unless ( exists $dimension->[$position] ) {
        foreach ( ref( $data ) eq 'ARRAY' ? @$data : ( $data ) ) {
            unless (ref( $_ ) eq 'HASH'
                and defined $_->{val}
                and defined $_->{count} )
            {
                $self->AddError(
                    App::DSC::DataTool::Error->new(
                        tag     => 'INVALID_DATA',
                        args    => { name => $name },
                        message => 'Invalid data for ' . $name
                    )
                );
                next;
            }

            $dimension->[ $position - 1 ]->{obj}->AddValues( $_->{val} => $_->{count} );
        }

        return;
    }

    foreach ( ref( $data ) eq 'ARRAY' ? @$data : ( $data ) ) {
        next if ref( $_ ) eq 'HASH' and exists $_->{content};
        unless ( ref( $_ ) eq 'HASH'
            and exists $_->{ $dimension->[$position]->{type} } )
        {
            $self->AddError(
                App::DSC::DataTool::Error->new(
                    tag     => 'INVALID_STRUCTURE',
                    args    => { name => $name },
                    message => 'Invalid structure for ' . $name
                )
            );
            next;
        }

        if ( $dimension->[$position]->{type} eq 'All' ) {
            delete $_->{ $dimension->[$position]->{type} }->{val};
        }

        $self->Process(
            $name,
            $_->{ $dimension->[$position]->{type} },
            $dimension,
            $position + 1
        );
    }

    return;
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

1;    # End of App::DSC::DataTool::Input::XML
