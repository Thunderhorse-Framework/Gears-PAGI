package Gears::PAGI::Request;

use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;
use Hash::MultiValue;
use Cookie::Baker qw(crush_cookie);

with 'Gears::Role::HasContext';

has field 'headers' => (
	(STRICT ? (InstanceOf ['Hash::MultiValue']) : ()),
	lazy => 1,
	clearer => 1,
);

has field 'cookies' => (
	(STRICT ? (HashRef) : ()),
	lazy => 1,
	clearer => 1,
);

sub _build_headers ($self)
{
	my $headers = $self->context->scope->{headers} // [];
	return Hash::MultiValue->new(map { $_->@* } $headers->@*);
}

sub _build_cookies ($self)
{
	return crush_cookie($self->header('cookie'));
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

sub cookie ($self)
{
	return $self->cookies->{$name};
}


sub query_param ($self)
{
}

sub query_parameters ($self)
{
}

sub raw_query_parameters ($self)
{
}


sub body_param ($self)
{
}

sub body_parameters ($self)
{
}

sub raw_body_parameters ($self)
{
}

sub body ($self)
{
}

sub raw_body ($self)
{
}

