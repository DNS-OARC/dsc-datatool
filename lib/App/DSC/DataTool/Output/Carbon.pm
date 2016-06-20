package App::DSC::DataTool::Output::Carbon;

use common::sense;
use Carp;

use base qw(App::DSC::DataTool::Output);

use IO::Socket::INET;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Output::Carbon - Output DSC data to Carbon

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Output DSC data to Carbon...

=head1 METHODS

=over 4

=item $output->Init (...)

Initialize the Carbon output, called from the output factory.

=over 4

=item host

=item port

=item timestamp (optional)

=back

=cut

sub Init {
    my ( $self, %args ) = @_;

    foreach ( qw(host port) ) {
        unless ( $args{$_} ) {
            croak $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
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

    $self->{carbon} = IO::Socket::INET->new(
        PeerAddr => $self->{host},
        PeerPort => $self->{port},
        Proto    => 'tcp'
    );
    unless ( $self->{carbon}->connected ) {
        croak 'Unable to connect to ' . $self->{host} . '[' . $self->{port} . ']: ' . $!;
    }

    return $self;
}

=item $output->Destroy

Disconnect from the Carbon server and destroy the object.

=cut

sub Destroy {
    $_[0]->{carbon}->shutdown( 2 );
    return;
}

=item $name = $output->Name

Return the name of the module, must be overloaded.

=cut

sub Name {
    'Carbon';
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
        my $name = $dataset->Name;
        $name =~ s/\./-/go;
        my $timestamp =
            $self->{timestamp} eq 'start'
          ? $dataset->StartTime
          : $dataset->StopTime;

        foreach my $dimension ( $dataset->Dimensions ) {
            $self->Process( $name, $timestamp, $dimension );
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
    my ( $self, $name, $timestamp, $dimension ) = @_;

    if ( $dimension->HaveDimensions ) {
        my $dimension_name = $dimension->Value;
        $dimension_name =~ s/\./-/go;
        $name .= '.' . $dimension_name;

        foreach my $dimension2 ( $dimension->Dimensions ) {
            $self->Process( $name, $timestamp, $dimension2 );
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
    foreach my $key ( keys %value ) {
        my $value = $value{$key};
        $key =~ s/\./-/go;

        $self->{carbon}->send( join( ' ', $name . '.' . $key, $value, $timestamp ) . "\n" );
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

1;    # End of App::DSC::DataTool::Output
