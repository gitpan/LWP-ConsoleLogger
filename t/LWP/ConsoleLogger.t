use strict;
use warnings;

use HTTP::Request;
use LWP::ConsoleLogger;
use LWP::UserAgent;
use Path::Tiny qw( path );
use Test::Fatal qw( exception );
use Test::Most;
use URI::file;
use WWW::Mechanize;

my @mech = ( LWP::UserAgent->new( cookie_jar => {} ), WWW::Mechanize->new );
my $logger = LWP::ConsoleLogger->new( dump_content => 1, dump_text => 1 );
ok( $logger, 'logger compiles' );

foreach my $mech ( @mech ) {
    $mech->default_header(
        'Accept-Encoding' => scalar HTTP::Message::decodable() );
    is( exception { get_local_file( $mech ) }, undef, 'code lives' );
}

$logger->content_pre_filter(
    sub {
        my $content      = shift;
        my $content_type = shift;
        diag "Content-Type: $content_type";

        if ( $content
            =~ m{<!-- \s header \s ends \s -->(.*)<!-- \s footer \s begins \s -->}gmxs
            )
        {
            return $1;
        }
        return $content;
    }
);

$mech[0]
    ->get( 'file:///' . path( 't/test-data/content-regex.html' )->absolute );

sub get_local_file {
    my $mech = shift;
    $mech->add_handler( 'response_done',
        sub { $logger->response_callback( @_ ) } );
    $mech->add_handler( 'request_send',
        sub { $logger->request_callback( @_ ) } );
    my $uri = URI::file->new( path( 't/test-data/foo.html' )->absolute );

    $mech->get( $uri );
}

done_testing();
