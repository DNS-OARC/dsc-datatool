package App::DSC::DataTool::Log;

use common::sense;
use Carp;

use Scalar::Util qw( blessed );
use POSIX;

our $INSTANCE;

=encoding utf8

=head1 NAME

App::DSC::DataTool::Log - Log various things for App::DSC::DataTool

=head1 VERSION

See L<App::DSC::DataTool> for version.

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

Log various things for App::DSC::DataTool...

=head1 METHODS

=over 4

=item $log = App::DSC::DataTool::Input->new ( key => value ... )

Create a new log object.

=over 4

=item verbose (optional)

Only display/output logging up to and including this verbose level, default 0.

=item timestamp (optional)

Add timestamp to the begining of each log message, default true(1).

=back

=cut

sub new {
    my ( $this, %args ) = @_;
    my $class = ref( $this ) ? ref( $this ) : $this;
    my $self = {
        verbose   => 0,
        timestamp => 1,
    };
    bless $self, $class;

    foreach ( qw( verbose timestamp ) ) {
        if ( $args{$_} ) {
            $self->{$_} = $args{$_};
        }
    }

    #TODO: config output

    return $self;
}

=item $inputs = App::DSC::DataTool::Log->instance ( key => values ... )

Return a singelton of the log module. Arguments are passed to B<new()> only
the first time it's called and that should be done during program
initialization to setup the default instance of logging.

=cut

sub instance {
    shift;
    return $INSTANCE ||= App::DSC::DataTool::Log->new( @_ );
}

=item $verbose = $log->Verbose

Return the verbose level.

=cut

sub Verbose {
    return $_[0]->{verbose};
}

=item $log = $log->log( $class, $verbose, < @messages | $error > )

Log a message.

TODO: documentation

=over 4

=item $class

=item $verbose

=item @messages

=item $error

=back

=cut

sub log {
    my ( $self, $class, $verbose, @messages ) = @_;

    unless ( $verbose <= $self->{verbose} ) {
        return $self;
    }

    #TODO: check class

    if ( scalar @messages == 1 and blessed $messages[0] and $messages[0]->isa( 'App::DSC::DataTool::Error' ) ) {
        @messages = ( $messages[0]->to_string );
    }

    say STDERR
      ( $self->{timestamp} ? strftime( '%Y-%m-%d %H:%M:%S ', localtime ) : '' ),
      $class, ': ', @messages;

    return $self;
}

#TODO: sub debug
#TODO: sub info
#TODO: sub warning
#TODO: sub error
#TODO: sub critical

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

1;    # End of App::DSC::DataTool::Log
