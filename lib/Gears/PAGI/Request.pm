package Gears::PAGI::Request;

use v5.40;
use Mooish::Base -standard;

use Future::AsyncAwait;
use Devel::StrictMode;
use Hash::MultiValue;
use Cookie::Baker qw(crush_cookie);
use URL::Encode qw(url_params_flat);
use HTTP::Body;
use Gears;

with 'Gears::Role::HasContext';

has param 'charset' => (
	(STRICT ? (isa => SimpleStr) : ()),
	default => 'utf-8',
);

has param 'streamed_body' => (
	(STRICT ? (isa => Bool) : ()),
	default => false,
	writer => 1,
);

has field 'incoming_charset' => (
	(STRICT ? (isa => Maybe [SimpleStr]) : ()),
	lazy => 1,
);

sub _build_incoming_charset ($self)
{
	my $ct = $self->content_type;

	return undef unless $ct;
	return undef unless $ct =~ m{
        ^(?:                  # only on some content-types
            text/ | application/
        )
        .+
        ;\s*charset=([^;\$]+) # get the charset
    }xi;

	return $1;
}

sub _build_headers ($self)
{
	my $headers = $self->context->scope->{headers} // [];
	return Hash::MultiValue->new(map { $_->@* } $headers->@*);
}

sub _build_cookies ($self)
{
	return crush_cookie($self->header('cookie'));
}

sub _build_query ($self)
{
	return Hash::MultiValue->new(url_params_flat($self->query_string)->@*);
}

sub _build_body ($self)
{
	my $body = HTTP::Body->new($self->content_type, $self->content_length);
	$body->cleanup(true);
	return $body;
}

sub headers ($self)
{
	return $self->context->scope->{'gears.request.headers'}
		//= $self->_build_headers;
}

sub cookies ($self)
{
	return $self->context->scope->{'gears.request.cookies'}
		//= $self->_build_cookies;
}

sub path ($self)
{
	return $self->context->scope->{path};
}

sub raw_path ($self)
{
	my $scope = $self->context->scope;
	return $scope->{raw_path} // $scope->{path};
}

sub method ($self)
{
	return $self->context->scope->{method};
}

sub query_string ($self)
{
	return $self->context->scope->{query_string} // '';
}

sub scheme ($self)
{
	return $self->context->scope->{scheme} // 'http';
}

sub host ($self)
{
	return $self->header('host');
}

sub content_type ($self)
{
	return $self->header('content-type') =~ s{;.*}{}r;
}

sub content_length ($self)
{
	return $self->header('content-length');
}

sub header ($self, $name)
{
	return $self->headers->get(lc $name);
}

sub cookie ($self, $name)
{
	return $self->cookies->{$name};
}

sub content_type_is ($self, $type)
{
	return 0 unless $self->content_type;
	return $self->content_type =~ m{^\Q$type\E}i;
}

sub is_text ($self)
{
	return $self->content_type_is('text/plain');
}

sub is_html ($self)
{
	return $self->content_type_is('text/html');
}

sub is_json ($self)
{
	return $self->content_type_is('application/json');
}

sub is_xml ($self)
{
	return $self->content_type_is('application/xml');
}

sub is_octet_stream ($self)
{
	return $self->content_type_is('application/octet-stream');
}

sub query_param ($self, $name)
{
	my $value = $self->raw_query->get($name);

	return $self->charset_decode($value);
}

sub raw_query ($self)
{
	return $self->context->scope->{'gears.request.raw_query'}
		//= $self->_build_query;
}

async sub body_param ($self, $name)
{
	my $value = (await $self->raw_body)->param->{$name};
	$value = $value->[-1] if ref $value eq 'ARRAY';

	return $self->charset_decode($value);
}

async sub upload ($self, $name)
{
	my $value = (await $self->raw_body)->upload->{$name};
	$value = $value->[-1] if ref $value eq 'ARRAY';

	return $value;
}

my async sub stream_body ($self)
{
	my $receive = $self->context->receiver;

	my $msg = await $receive->();
	if (!$msg || $msg->{type} eq 'http.disconnect') {
		return ('', false);
	}

	# TODO: check for http.request type?
	return ($msg->{body}, $msg->{more});
}

async sub raw_body ($self)
{
	if (!$self->streamed_body) {
		await $self->load_more_body while $self->more_body;
	}

	return $self->context->scope->{'gears.request.raw_body'} //= $self->_build_body;
}

sub more_body ($self)
{
	return $self->context->scope->{'gears.request.more_body'} // true;
}

async sub load_more_body ($self)
{
	my $scope = $self->context->scope;
	my $body = $scope->{'gears.request.raw_body'} //= $self->_build_body;
	my $ref_more = \$scope->{'gears.request.more_body'};

	$$ref_more //= true;
	if ($$ref_more) {
		(my $part, $$ref_more) = await stream_body($self);
		$body->add($part);
	}

	return $self;
}

sub charset_decode ($self, $string, $configured_only = false)
{
	my $charset = $self->charset;

	# do not decode at all if this request instance is set to not decode
	return $string unless $charset;

	return Gears::charset_decode(
		(!$configured_only && Gears::effective_charset($self->incoming_charset)) || $charset,
		$string,
	);
}

