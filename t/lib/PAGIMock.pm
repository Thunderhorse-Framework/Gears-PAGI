package PAGIMock;

use v5.40;
use Exporter qw(import);

use Future::AsyncAwait;
use URL::Encode qw(url_encode_utf8);
use PAGIConnectionMock;

our @EXPORT_OK = qw(
	mock_http
);

sub mock_receive_send ($receive_queue, $send_queue)
{
	my $receive = async sub {
		return shift $receive_queue->@*;
	};

	my $send = async sub ($msg) {
		push $send_queue->@*, $msg;
	};

	return ($receive, $send);
}

sub mock_http (%args)
{
	$args{query} = join '&',
		map {
			join '=', map { url_encode_utf8 $_ } $_->@*
		}
		($args{query} // [])->@*;

	$args{path} =~ s{^([^/])}{/$1};

	my $scope = {
		type => 'http',
		pagi => {
			version => '0.6',
		},
		http_version => '1.1',
		method => $args{method} // 'GET',
		path => $args{path} // '/',
		query_string => $args{query},
		headers => $args{headers} // [],
		client => ['192.168.1.1', 3000],
		server => ['192.168.1.1', 3000],
		state => {},
		'pagi.connection' => PAGIConnectionMock->new,
	};

	$args{receive_queue} //= [];
	$args{send_queue} //= [];

	my ($receive, $send) = mock_receive_send(@args{qw(receive_queue send_queue)});

	return ($scope, $receive, $send);
}

