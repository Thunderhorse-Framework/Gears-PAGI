package Gears::PAGI::Context;

use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;

extends 'Gears::Context';

has param 'pagi' => (
	(STRICT ? (isa => Tuple [HashRef, CodeRef, CodeRef]) : ()),
	writer => -hidden,
);

has field 'req' => (
	(STRICT ? (isa => InstanceOf ['Gears::PAGI::Request']) : ()),
	builder => 1,
);

has field 'res' => (
	(STRICT ? (isa => InstanceOf ['Gears::PAGI::Response']) : ()),
	predicate => 1,
	lazy => 1,
	clearer => -hidden,
);

has field 'ws' => (
	(STRICT ? (isa => InstanceOf ['Gears::PAGI::WebSocket']) : ()),
	predicate => 1,
	lazy => 1,
);

has field 'sse' => (
	(STRICT ? (isa => InstanceOf ['Gears::PAGI::SSE']) : ()),
	predicate => 1,
	lazy => 1,
);

sub _build_req ($self)
{
	return Gears::PAGI::Request->new(context => $self);
}

sub _build_res ($self)
{
	return Gears::PAGI::Response->new(context => $self);
}

sub _build_ws ($self)
{
	return Gears::PAGI::WebSocket->new(context => $self);
}

sub _build_sse ($self)
{
	return Gears::PAGI::SSE->new(context => $self);
}

sub scope ($self)
{
	return $self->pagi->[0];
}

sub receiver ($self)
{
	return $self->pagi->[1];
}

sub sender ($self)
{
	return $self->pagi->[2];
}

sub update ($self, $scope, $receive, $send)
{
	$self->_set_pagi([$scope, $receive, $send]);
}

sub connection
{
	return $self->scope->{'pagi.connection'};
}

sub empty_res ($self)
{
	$self->_clear_res;
	return $self->res;
}

