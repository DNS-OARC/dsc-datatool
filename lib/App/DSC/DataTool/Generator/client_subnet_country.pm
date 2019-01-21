package App::DSC::DataTool::Generator::client_subnet_country;

use common::sense;

use IP::Country::Fast;

use App::DSC::DataTool::Dataset;
use App::DSC::DataTool::Dataset::Dimension;

use base qw( App::DSC::DataTool::Generator );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Generator::client_subnet_country - Generate country based on subnet

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

...

=head1 METHODS

=over 4

=item Init

=cut

sub Init {
    $_[0]->{fast} = IP::Country::Fast->new;

    return $_[0];
}

=item Name

=cut

sub Name {
    return 'client_subnet_country';
}

=item Dataset

=cut

sub Dataset {
    my ( $self, $dataset ) = @_;

    unless ( $dataset->Name eq 'client_subnet' ) {
        return;
    }

    my ( %subnet, %country );

    my @dimensions = $dataset->Dimensions;
    while ( my $dimension = shift( @dimensions ) ) {
        if ( $dimension->Name eq 'ClientSubnet' and $dimension->HaveValues ) {
            my %value = $dimension->Values;
            foreach my $key ( keys %value ) {
                if ( $key eq $self->{skipped_key} or $key eq $self->{skipped_sum_key} ) {
                    $country{'__'} += $value{$key};
                    next;
                }

                $subnet{$key} += $value{$key};
            }
        }
        else {
            push( @dimensions, $dimension->Dimensions );
        }
    }

    foreach ( keys %subnet ) {
        my $cc = $self->{fast}->inet_atocc( $_ );
        $cc ||= '??';

        $country{$cc} += $subnet{$_};
    }

    my $dimension = App::DSC::DataTool::Dataset::Dimension->new( name => 'ClientCountry' )->SetValues( %country );

    my $country = App::DSC::DataTool::Dataset->new(
        name       => 'client_subnet_country',
        server     => $dataset->Server,
        node       => $dataset->Node,
        start_time => $dataset->StartTime,
        stop_time  => $dataset->StopTime,
    )->AddDimension( $dimension );

    return $country;
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

1;    # End of App::DSC::DataTool::Generator::client_subnet_country
