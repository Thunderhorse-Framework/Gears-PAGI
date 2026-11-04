package Gears::PAGI;

use v5.40;
use Future::AsyncAwait;
use List::Util qw(uniq);

use Devel::StrictMode;

async sub handle_lifespan ($scope, $receive, $send, %events)
{
	# NOTE: must be run for 'lifespan' scope - checked in development mode
	die 'bad scope type for lifespan handling - forgot to check scope?'
		if STRICT && $scope->{type} ne 'lifespan';

	my %known_events = map { $_ => true } uniq keys %events, qw(startup shutdown);

	while ('handling lifespan') {
		my $message = await $receive->();
		my $type = $message->{type};

		next unless $type =~ s{^lifespan\.}{};

		# TODO: make sure events can be forwarded (overwrite $receive, $send?)
		if ($known_events{$type}) {
			try {
				await $events{$type}->($scope, $receive, $send)
					if $events{$type};

				await $send->({
					type => "lifespan.$type.complete",
				});
			}
			catch ($e) {
				await $send->({
					type => "lifespan.$type.failed",
					message => "$e",
				});
			}
		}

		# NOTE: ignores events which are not known
	}
}

__END__

=head1 NAME

Gears::PAGI - New module

=head1 SYNOPSIS

	use Gears::PAGI;

	# do something

=head1 DESCRIPTION

This module lets you blah blah blah.

=head1 SEE ALSO

L<Some::Module>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

