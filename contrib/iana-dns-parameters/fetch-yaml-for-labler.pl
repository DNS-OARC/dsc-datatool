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
    foreach ( qw(rcode client_addr_vs_rcode rcode_vs_replylen) ) {
        my %copy = %rcode;
        $label{$_}->{Rcode} = \%copy;
    }
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
                if ( $type eq '*' ) {
                    $type = 'wildcard';
                }
                $qtype{$value} = $type;
            }
        }
    }
    foreach ( qw(qtype transport_vs_qtype certain_qnames_vs_qtype qtype_vs_tld qtype_vs_qnamelen chaos_types_and_names dns_ip_version_vs_qtype) ) {
        my %copy = %qtype;
        $label{$_}->{Qtype} = \%copy;
    }
}
else {
    die $response->status_line;
}

# OPCODE

my $response = $ua->get( 'http://www.iana.org/assignments/dns-parameters/dns-parameters-5.csv' );
if ( $response->is_success ) {
    my %opcode;
    my $head = 1;
    foreach ( split( /[\r\n]+/o, $response->decoded_content ) ) {
        if ( $head ) {
            $head = 0;
            next;
        }

        my ( $value, $name ) = split( /[,\s]+/o );
        $name =~ s/["']+//go;
        if ( defined $value and $name ) {
            $opcode{$value} = $name;
        }
    }
    foreach ( qw(opcode) ) {
        my %copy = %opcode;
        $label{$_}->{Opcode} = \%opcode;
    }
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
