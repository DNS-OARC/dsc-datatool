package App::DSC::DataTool::Dataset;

use common::sense;
use Carp;

use Scalar::Util qw(blessed);

=encoding utf8

=head1 NAME

App::DSC::DataTool::Dataset - Container for one DSC dataset and it's dimensions

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Container for one DSC dataset and it's dimensions...

=head1 METHODS

=over 4

=item $dataset = App::DSC::DataTool::Dataset->new (...)

Create a new dataset object.

=over 4

=item name

=item start_time

=item stop_time

=back

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        name       => undef,
        start_time => undef,
        stop_time  => undef,
        dimensions => [],
    };
    bless $self, $class;

    foreach ( qw( name start_time stop_time ) ) {
        unless ( $args{$_} ) {
            confess $_ . ' must be given';
        }
        $self->{$_} = $args{$_};
    }

    return $self;
}

=item $name = $dataset->Name

Return the name of the dataset.

=cut

sub Name {
    return $_[0]->{name};
}

=item $start_time = $dataset->StartTime

Return the start time of the dataset.

=cut

sub StartTime {
    return $_[0]->{start_time};
}

=item $stop_time = $dataset->StopTime

Return the stop time of the dataset.

=cut

sub StopTime {
    return $_[0]->{stop_time};
}

=item $dataset = $dataset->AddDimension ( <dimensions...> )

Adds the dimensions to the dataset, returns itself on success or confesses.

=cut

sub AddDimension {
    my $self = shift;

    if ( scalar @_ ) {
        foreach ( @_ ) {
            unless ( blessed $_ and $_->isa( 'App::DSC::DataTool::Dataset::Dimension' ) ) {
                confess 'argument is not App::DSC::DataTool::Dataset::Dimension';
            }
        }

        push( @{ $self->{dimensions} }, @_ );
    }

    return $self;
}

=item @dimensions = $dataset->Dimensions

Return the list of dimensions within the dataset.

=cut

sub Dimensions {
    return @{ $_[0]->{dimensions} };
}

=item $bool = $dataset->HaveDimensions

Return true(1) if there are dimensions otherwise false(0).

=cut

sub HaveDimensions {
    return scalar @{ $_[0]->{dimensions} } ? 1 : 0;
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

1;    # End of App::DSC::DataTool::Dataset
