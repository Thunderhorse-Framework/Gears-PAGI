use Test2::V1 -ipP;
use Gears::PAGI::Context;
use Encode qw(encode);
use URL::Encode qw(url_encode_utf8);
use List::Util qw(sum);

use lib 't/lib';
use PAGIMock qw(mock_http);

use utf8;

################################################################################
# This tests various functions of the request
################################################################################

subtest 'should create a request and provide correct scope data' => sub {
	my @recv = (
		{
			type => 'http.request',
			body => '11=22',
			more => 1,
		},
		{
			type => 'http.request',
			body => '&33=44&11=' . url_encode_utf8('zażółć gęślą jaźń'),
			more => 0,
		}
	);

	my $length = sum map { length $_->{body} } @recv;

	my @pagi = mock_http(
		path => 'a/b/c',
		query => [
			[one => 'two'],
			[three => 'zażółć gęślą jaźń'],
			[one => 'five'],
		],
		method => 'POST',
		headers => [
			['host', 'test'],
			['content-length', $length],
			['content-type', 'application/x-www-form-urlencoded'],
			['cookie', 'session=abc123; theme=dark; session=def456'],
			['x-test', 'one'],
			['x-test', 'two'],
		],
		receive_queue => \@recv,
	);

	my $context = Gears::PAGI::Context->new(
		pagi => \@pagi,
	);

	my $req = $context->req;
	is $req->path, '/a/b/c', 'path ok';
	is $req->query_string, 'one=two&three=' . url_encode_utf8('zażółć gęślą jaźń') . '&one=five',
		'query string ok';
	is $req->raw_path, $req->path, 'path and raw_path are the same ok';
	is $req->method, 'POST', 'method ok';
	is $req->scheme, 'http', 'scheme ok';
	is $req->host, 'test', 'host ok';
	is $req->content_length, $length, 'content_length ok';

	ok $req->content_type, 'application/x-www-form-urlencoded', 'content_type ok';
	ok $req->content_type_is('application/x-www-form-urlencoded'), 'content_type_is ok';

	is $req->header('X-Test'), 'two', 'X-Test header ok';
	is [$req->headers->get_all('x-test')], ['one', 'two'], 'raw header access ok';

	is $req->cookie('theme'), 'dark', 'cookie ok';
	is $req->cookies->{session}, 'abc123', 'raw cookie access ok';

	is $req->query_param('one'), 'five', 'query param ok';
	is $req->query_param('three'), 'zażółć gęślą jaźń', 'query param decoded ok';
	is $req->raw_query->get('three'), encode('utf-8', 'zażółć gęślą jaźń'), 'query param raw ok';
	is [$req->raw_query->get_all('one')], ['two', 'five'], 'raw query access ok';

	is $req->body_param('33')->get, '44', 'body param ok';
	is $req->body_param('11')->get, 'zażółć gęślą jaźń', 'body param decoded ok';
	is $req->raw_body->get->param->{11}, ['22', encode 'utf-8', 'zażółć gęślą jaźń'], 'raw body access ok';
};

done_testing;

