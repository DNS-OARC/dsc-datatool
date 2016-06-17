#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::DSC::DataTool' ) || print "Bail out!\n";
}

diag( "Testing App::DSC::DataTool $App::DSC::DataTool::VERSION, Perl $], $^X" );
