package App::DSC::DataTool::Errors;

use common::sense;
use Carp;

use Scalar::Util qw( blessed );

=encoding utf8

=head1 NAME

App::DSC::DataTool::Errors - Error container

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Error container...

=head1 METHODS

=over 4

=item $input = $input->AddError ( $error )

Add an error, this should be used internally within modules to reports errors
during processing.

=over 4

=item $error

An App::DSC::DataTool::Error object describing the processing error.

=back

=cut

sub AddError {
    my ( $self, $error ) = @_;

    unless ( blessed $error and $error->isa( 'App::DSC::DataTool::Error' ) ) {
        confess '$error is not App::DSC::DataTool::Error';
    }

    push( @{ $self->{errors} }, $error );

    return $self;
}

=item $error = $input->GetError

Remove one error from the list of errors and return it, may return undef if
there are no errors.

=over 4

=item $error

An App::DSC::DataTool::Error object describing the processing error.

=back

=cut

sub GetError {
    return shift @{ $_[0]->{errors} };
}

=item @errors = $input->Errors

Return a list of errors if any, this does not reset errors.

=over 4

=item @errors

A list of App::DSC::DataTool::Error objects.

=back

=cut

sub Errors {
    return @{ $_[0]->{errors} };
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

1;    # End of App::DSC::DataTool::Errors
