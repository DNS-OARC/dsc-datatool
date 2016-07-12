#!/usr/bin/env perl

use common::sense;

use LWP::UserAgent;
use YAML::Tiny;

my %label;

# RCODE

my $ua       = LWP::UserAgent->new;
my $response = $ua->get( 'http://www.iana.org/assignments/dns-parameters/dns-parameters-6.csv' );
if ( $response->is_success ) {
    my %rcode;
    my $head = 1;
    foreach ( split( /[\r\n]+/o, $response->decoded_content ) ) {
        if ( $head ) {
            $head = 0;
            next;
        }

        my ( $value, $name ) = split( /,/o );
        $name =~ s/["']+//go;
        if ( defined $value and $name ) {
            $rcode{$value} = $name;
        }
    }
    $label{rcode}->{Rcode} = \%rcode;
}
else {
    die $response->status_line;
}

# QTYPE

my $response = $ua->get( 'http://www.iana.org/assignments/dns-parameters/dns-parameters-4.csv' );
if ( $response->is_success ) {
    my %qtype;
    my $head = 1;
    foreach ( split( /[\r\n]+/o, $response->decoded_content ) ) {
        if ( $head ) {
            $head = 0;
            next;
        }

        if ( /^([^,]+),((?:\d+|\d+-\d+)),/o ) {
            my ( $type, $value ) = ( $1, $2 );
            if ( defined $value and $type ) {
                $qtype{$value} = $type;
            }
        }
    }
    $label{qtype}->{Qtype} = \%qtype;
}
else {
    die $response->status_line;
}

# Dump YAML

my $yaml = YAML::Tiny->new;

foreach my $name ( keys %label ) {
    $yaml->[0]->{$name} = $label{$name};
}
say $yaml->write_string;
