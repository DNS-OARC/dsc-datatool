package App::DSC::DataTool::Dataset::Dimension;

use common::sense;
use Carp;

use Scalar::Util qw( blessed );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Dataset::Dimension - Container for one DSC dimension and
it's subdimension or values

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Container for one DSC dimension and it's subdimension or values...

=head1 METHODS

=over 4

=item $dimension = App::DSC::DataTool::Dataset::Dimension->new (...)

Create a new dimension object.

=over 4

=item name

The name of the dimension.

=item value (optional)

The value of the dimension, when this is set then you can only add other
dimensions to the dimension and no values can be added.

=back

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {};
    bless $self, $class;

    unless ( $args{name} ) {
        confess 'name must be given';
    }
    $self->{name} = $args{name};

    if ( defined $args{value} ) {
        $self->{value} = $args{value};
    }

    return $self;
}

=item $name = $dimension->Name

Return the name of the dimension.

=cut

sub Name {
    return $_[0]->{name};
}

=item $value = $dimension->Value

Return the value of the dimension if set.

=cut

sub Value {
    return $_[0]->{value};
}

=item $dimension = $dimension->AddDimension ( <dimensions...> )

Adds the dimensions to the dimension, returns itself on success or confesses.

Dimensions can not be added if values exists.

=cut

sub AddDimension {
    my $self = shift;

    unless ( defined $self->{value} ) {
        confess 'value must be set to add dimensions';
    }
    if ( exists $self->{values} ) {
        confess 'Values exists, can not add dimensions';
    }

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

=item @dimensions = $dimension->Dimensions

Return the list of dimensions within the dimension.

=cut

sub Dimensions {
    return exists $_[0]->{dimensions} ? @{ $_[0]->{dimensions} } : ();
}

=item $bool = $dataset->HaveDimensions

Return true(1) if there are dimensions otherwise false(0).

=cut

sub HaveDimensions {
    return exists $_[0]->{dimensions} && scalar @{ $_[0]->{dimensions} } ? 1 : 0;
}

=item $dimension = $dimension->AddValues ( key => value, ... )

Add values to the dimension, returns itself on success or confesses.

Values can not be added if dimensions exists.

=cut

sub AddValues {
    my $self = shift;

    if ( defined $self->{value} ) {
        confess 'value must not be set to add values';
    }
    if ( exists $self->{dimensions} ) {
        confess 'Dimensions exists, can not add values';
    }

    my $key;
    foreach ( @_ ) {
        unless ( defined $key ) {
            $key = $_;
            next;
        }

        $self->{values}->{$key} = $_;
        $key = undef;
    }

    if ( defined $key ) {
        confess 'Number of key => value is not even, missing last value';
    }

    return $self;
}

=item %value = $dimension->Values

Return the hash of values within the dimension.

=cut

#TODO: better handling of values

sub Values {
    return exists $_[0]->{values} ? %{ $_[0]->{values} } : ();
}

=item $bool = $dataset->HaveValues

Return true(1) if there are values otherwise false(0).

=cut

sub HaveValues {
    return exists $_[0]->{values} && scalar %{ $_[0]->{values} } ? 1 : 0;
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

1;    # End of App::DSC::DataTool::Dataset::Dimension
