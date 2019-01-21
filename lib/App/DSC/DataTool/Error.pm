package App::DSC::DataTool::Error;

use common::sense;
use Carp;

use Scalar::Util qw( blessed );

#TODO: SEVERITIES

=encoding utf8

=head1 NAME

App::DSC::DataTool::Error - Object used to describe an error

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Object used to describe an error...

=head1 METHODS

=over 4

=item $error = App::DSC::DataTool::Error->new ( key => value ... )

Create a new error object.

=over 4

=item severity (optional)

Level of error severity, see SEVERITIES. Default to 'err'.

=item reporter (optional)

The module that reported the error, if a reference is given L<ref()> will be
used to set the name. Default to the caller.

=item tag (optional)

A custom error tag that is defined by the reporter. Default to 'ERROR'.

=item args (optional)

A hash of the arguments relative to the error.

=item message

The error message.

=back

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        severity => 'ERROR',
        reporter => ( caller )[0],
        tag      => 'UNKNOWN',
        args     => {},
        message  => undef,
    };
    bless $self, $class;

    if ( $args{severity} ) {

        #TODO
    }
    if ( $args{reporter} ) {
        $self->{reporter} = ref( $args{reporter} ) ? ref( $args{reporter} ) : $args{reporter};
    }
    if ( $args{tag} ) {
        $self->{tag} = $args{tag};
    }
    if ( $args{args} ) {
        unless ( ref( $args{args} ) eq 'HASH' ) {
            confess 'args is not HASH';
        }
        $self->{args} = $args{args};
    }
    unless ( $args{message} ) {
        confess 'message must be set';
    }
    $self->{message} = $args{message};

    return $self;
}

=item $severity = $error->Severity

Return the severity of the error.

=cut

sub Severity {
    return $_[0]->{severity};
}

=item $reporter = $error->Reporter

Return the reporter of the error.

=cut

sub Reporter {
    return $_[0]->{reporter};
}

=item $tag = $error->Tag

Return the tag of the error.

=cut

sub Tag {
    return $_[0]->{tag};
}

=item $args = $error->Args

Return the arguments of the error.

=cut

sub Args {
    return $_[0]->{args};
}

=item $message = $error->Message

Return the message of the error.

=cut

sub Message {
    return $_[0]->{message};
}

=item $string = $error->to_string

Return an string representation of the error.

=cut

sub to_string {
    return '[' . $_[0]->{reporter} . ']' . ' ' . $_[0]->{tag} . ' ' . $_[0]->{severity} . ': ' . $_[0]->{message};
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

1;    # End of App::DSC::DataTool::Error
