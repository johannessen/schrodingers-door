#! /usr/bin/env perl

use v5.36;  # v5.38: see mojo#2094
use Mojolicious::Lite;
use Mojo::Util qw(xml_escape);

use lib 'lib';
use Local::Mission;

my $mission = Local::Mission->new;
$mission->load('schrodingers-door');


app->helper(my_session => sub ($c) {
	my %session = (
		scene => $c->session('scene') // 0,
		stats => $c->session('stats') // {
			strength     => 100,
			stamina      => 100,
			agility      => 100,
			intelligence => 100,
			social       => 100,
		},
		last_choice => $c->session('last_choice') // '',
	);
	$c->session(%session);
	return \%session;
});


get '/' => sub ($c) {
	if (defined $c->session('scene')) {
		my $session = $c->my_session;
		return $c->redirect_to('authors-note')
			if $session->{scene} == $mission->scenes && $session->{last_choice} eq 'success';
		return $c->redirect_to('mission');
	}
	$c->render(
		template => 'default',
		mission => $mission,
	);
} => 'default';


get '/mission' => sub ($c) {
	my $session = $c->my_session;
	return $c->redirect_to('authors-note')
		if $session->{scene} == $mission->scenes && $session->{last_choice} eq 'success';
	
	my (@lines, @choices);
	push @lines, $mission->lines_for_choice($session->{last_choice});
	push @lines, $mission->lines_for_scene($session->{scene});
	@choices = map { $_ => $mission->choices->{$_} } (pop @lines)->{choice}->@*
		if ref $lines[$#lines] eq 'HASH' && $lines[$#lines]->{choice};
	my $action = $c->url_for('choice');
	
	if (! @choices) {  # Shouldn't happen; probably indicates a bug
		@choices = (failure => $mission->choices->{failure});
		$action = $c->url_for('reset');
	}
	if ($choices[0] eq 'success') {
		$action = $c->url_for('success');
	}
	
	$c->render(
		mission => $mission,
		lines => \@lines,
		choices => \@choices,
		action => $action,
	);
} => 'mission';


app->helper(choice_valid => sub ($c, $id) {
	my $choices = $mission->choices;
	return 0 unless $id && $choices->{$id};
	my $uses_stat = $choices->{$id}{uses};
	return 1 unless $uses_stat;
	return $c->session('stats')->{$uses_stat} >= 20;
});


post '/mission/choice' => sub ($c) {
	my $choice = $c->param('choice') // '';
	return $c->reply->exception unless $c->choice_valid($choice);
	
	my $session = $c->my_session;
	my $next_scene = $session->{scene} + 1;
	++$next_scene if $choice =~ m/^skip\b/;
	if (my $uses_stat = $mission->choices->{$choice}{uses}) {
		my $stats = $session->{stats};
		$stats->{$uses_stat} = 0;
	}
	$c->app->log->info("Mission choice $choice");
	$c->session( scene => $next_scene, last_choice => $choice );
	$c->redirect_to('mission');
} => 'choice';


get '/authors-note' => sub ($c) {
	$c->render( mission => $mission );
} => 'authors-note';


post '/mission/success' => sub ($c) {
	$c->app->log->info('Mission success');
	$c->session( scene => $c->my_session->{scene} + 1, last_choice => 'success' );
	$c->redirect_to('authors-note');
} => 'success';


post '/mission/reset' => sub ($c) {
	$c->app->log->info('Mission reset');
	$c->session( expires => 1 );
	$c->redirect_to('default');
} => 'reset';


post '/mission/start' => sub ($c) {
	$c->app->log->info('Mission start');
	$c->session( expires => 1 );
	$c->redirect_to('mission');
} => 'start';


get '/singlepage' => sub ($c) {
	$c->render( mission => $mission );
} => 'singlepage';


app->helper(md_escape => sub ($c, $str) {
	$str = xml_escape $str;
	
	# Emphasis via simple Markdown syntax
	$str =~ s{\*([^ ]+)\*}{<em>$1</em>}g;
	
	# Markup for common abbreviation
	$str =~ s{\bCORETECHS\b}{<abbr title="Cognitive Recall Enhancer Technology Stack">CORETECHS</abbr>}g;
	
	return $str;
});


app->sessions->cookie_name( app->moniker );
app->sessions->default_expiration( 3600 * 24 * 10 );

app->log->level('info');
app->log->path( '/srv/Log/' . app->moniker ) if -w '/srv/Log';

# Rewrite URLs depending on deployment requirements
app->hook(before_dispatch => sub ($c) {
	if (my $path = $c->req->headers->header('X-Forwarded-Path')) {
		$c->req->url->base->path->parse($path)->trailing_slash(1);
	}
	elsif ($ENV{GATEWAY_INTERFACE}) {
		pop @{$c->req->url->base->path->trailing_slash(1)};
	}
});

app->start;
