package App::DSC::DataTool::Output::InfluxDB;

use common::sense;
use Carp;

use base qw(App::DSC::DataTool::Output);

use IO::Socket::INET;
use IO::File;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Output::InfluxDB - Output DSC data to InfluxDB

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Output DSC data to InfluxDB...

=head1 METHODS

=over 4

=item $output->Init (...)

Initialize the InfluxDB output, called from the output factory.

=over 4

=item host

=item port

=item file

=item append (optional)

=item timestamp (optional)

=back

=cut

sub Init {
    my ( $self, %args ) = @_;

    #    if ( $args{file} ) {
    #        $self->{file} = $args{file};
    #    }
    #    else {
    #        foreach ( qw(host port) ) {
    #            unless ( $args{$_} ) {
    #                croak $_ . ' must be given';
    #            }
    #            $self->{$_} = $args{$_};
    #        }
    #    }
    foreach ( qw(append) ) {
        if ( defined $args{$_} ) {
            $self->{$_} = $args{$_};
        }
    }
    if ( $args{timestamp} ) {
        unless ( $args{timestamp} eq 'start'
            or $args{timestamp} eq 'end' )
        {
            croak 'invalid timestamp, must be "start" or "end"';
        }

        $self->{timestamp} = $args{timestamp};
    }
    else {
        $self->{timestamp} = 'start';
    }

    #    if ( $self->{file} ) {
    #        $self->{file_handle} = IO::File->new;
    #        unless ( $self->{file_handle}->open( $self->{file}, $self->{append} ? '>>' : '>' ) ) {
    #            croak 'Unable to open file ' . $self->{file} . ': ' . $!;
    #        }
    #    }
    #    else {
    #        $self->{influxdb} = IO::Socket::INET->new(
    #            PeerAddr => $self->{host},
    #            PeerPort => $self->{port},
    #            Proto    => 'udp'
    #        );
    #        unless ( $self->{influxdb}->connected ) {
    #            croak 'Unable to connect to ' . $self->{host} . '[' . $self->{port} . ']: ' . $!;
    #        }
    #    }

    return $self;
}

=item $output->Destroy

Disconnect from the InfluxDB server and destroy the object.

=cut

sub Destroy {

    #    $_[0]->{influxdb}->shutdown( 2 );
    return;
}

=item $name = $output->Name

Return the name of the module, must be overloaded.

=cut

sub Name {
    'InfluxDB';
}

=item $output = $output->Dataset ( @datasets )

Output a list of dataset objects, must be overloaded.

=over 4

=item @datasets

A list of L<App::DSC::DataTool::Dataset> objects to be outputted.

=back

=cut

sub Dataset {
    my $self = shift;

    foreach my $dataset ( @_ ) {
        my $tags = _quote( lc( $dataset->Name ) ) . ',server=' . _quote( $dataset->Server ) . ',node=' . _quote( $dataset->Node );
        my $timestamp =
            $self->{timestamp} eq 'start'
          ? $dataset->StartTime
          : $dataset->StopTime;
        $timestamp *= 1000000000;

        foreach my $dimension ( $dataset->Dimensions ) {
            $self->Process( $tags, $timestamp, $dimension );
        }
    }

    return $self;
}

=back

=head1 PRIVATE METHODS

=over 4

=item Process

=cut

sub Process {
    my ( $self, $tags, $timestamp, $dimension ) = @_;

    if ( $dimension->HaveDimensions ) {
        unless ( $dimension->Name eq 'All' and $dimension->Value eq 'ALL' ) {
            $tags .= ',' . _quote( lc( $dimension->Name ) ) . '=' . _quote( $dimension->Value );
        }

        foreach my $dimension2 ( $dimension->Dimensions ) {
            $self->Process( $tags, $timestamp, $dimension2 );
        }

        return;
    }

    unless ( $dimension->HaveValues ) {
        $self->AddError(
            App::DSC::DataTool::Error->new(
                tag     => 'NO_VALUES',
                args    => { dimension => $dimension->Name },
                message => 'Expected values in dimension ' . $dimension->Name
            )
        );
        return;
    }

    my %value = $dimension->Values;
    $tags .= ',' . _quote( lc( $dimension->Name ) ) . '=';
    foreach ( keys %value ) {
        say $tags, _quote( $_ ), ' value=', $value{$_}, ' ', $timestamp;
    }

    #    say $tags, ' ', join( ',', map { _quote( $_ ) . '=' . _quote( $value{$_} ) } keys %value ), ' ', $timestamp;

    #    my %value = $dimension->Values;
    #    if ( $self->{file_handle} ) {
    #        foreach my $key ( keys %value ) {
    #            say $tags, ' ', _quote( $key ), '=', _quote( $value{$key} ), ' ', $timestamp;
    #            $self->{file_handle}->say( join( ' ', $name . '.' . $self->nodots( $key ), $value{$key}, $timestamp ) );
    #        }
    #    }
    #    else {
    #        foreach my $key ( keys %value ) {
    #            $self->{influxdb}->send( join( ' ', $name . '.' . $self->nodots( $key ), $value{$key}, $timestamp ) . "\n" );
    #        }
    #    }

    return;
}

=item _quote

=cut

sub _quote {
    my ( $key ) = @_;
    $key =~ s/([,=\s])/\\$1/go;

    #    unless ( $_[0] =~ /^[a-zA-Z0-9_:\.-]+$/o ) {
    #        croak 'illegal character(s) in: ' . $_[0];
    #    }

    return $key;
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

1;    # End of App::DSC::DataTool::Output
