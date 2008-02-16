use strict;
use t::TestYAML ();
use Test::More tests => 14;

use JSON::Syck;

{
	# RFC 4627 only allows double-quoted string.
	$JSON::Syck::SingleQuote = 0;
	my $t;

	$t = JSON::Syck::Dump({ foo => "y" });
	like $t, qr/"y"/;

	$t = JSON::Syck::Dump({ foo => "n" });
	like $t, qr/"n"/;

	$t = JSON::Syck::Dump({ foo => "yes" });
	like $t, qr/"yes"/;

	$t = JSON::Syck::Dump({ foo => "no" });
	like $t, qr/"no"/;

	$t = JSON::Syck::Dump({ foo => "true" });
	like $t, qr/"true"/;

	$t = JSON::Syck::Dump({ foo => "false" });
	like $t, qr/"false"/;

	$t = JSON::Syck::Dump({ foo => "null" });
	like $t, qr/"null"/;
}
{
	# Violate RFC but needed?
	$JSON::Syck::SingleQuote = 1;
	my $t;

	$t = JSON::Syck::Dump({ foo => "y" });
	like $t, qr/'y'/;

	$t = JSON::Syck::Dump({ foo => "n" });
	like $t, qr/'n'/;

	$t = JSON::Syck::Dump({ foo => "yes" });
	like $t, qr/'yes'/;

	$t = JSON::Syck::Dump({ foo => "no" });
	like $t, qr/'no'/;

	$t = JSON::Syck::Dump({ foo => "true" });
	like $t, qr/'true'/;

	$t = JSON::Syck::Dump({ foo => "false" });
	like $t, qr/'false'/;

	$t = JSON::Syck::Dump({ foo => "null" });
	like $t, qr/'null'/;
}
