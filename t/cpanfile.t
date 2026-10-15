use strict;
use warnings;
use Test::More;

# api_endpoint is https-only and URI is used directly, so both must be declared.
open my $fh, '<', 'cpanfile' or BAIL_OUT('cannot open cpanfile: '.$!);
my %req;
while ( my $line = <$fh> ) {
  $req{$1} = 1 if $line =~ /^\s*requires\s+'([^']+)'/;
}
close $fh;

for my $mod ( qw( LWP::Protocol::https URI ) ) {
  ok( $req{$mod}, 'cpanfile requires '.$mod );
}

done_testing;
