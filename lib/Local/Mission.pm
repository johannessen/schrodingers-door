use v5.38;
use utf8;
use feature 'class';
no warnings 'experimental::class';


class Local::Mission;


use Path::Tiny;
use List::Util qw(first);
use YAML::Tiny ();

my @EXT = qw(yaml yml);


field $name;
field $summary;
field $choices;
field @scenes;


method load ($slug, $dir = 'templates') {
	my $path = path($dir);
	$path = first { $_->exists } map { $path->child("$slug.$_") } @EXT;
	die "Mission file '$slug' not found" unless defined $path;
	
	@scenes = YAML::Tiny->read($path->absolute)->@*;
	my $mission = shift @scenes;
	
	$name = $mission->{name};
	$summary = $mission->{summary};
	$choices = $mission->{choices};
	
	$choices->{success} //= {
		name => sprintf("You have completed the “%s” mission.", $name),
	};
	$choices->{failure} //= {
		name => "Congratulations, you found a bug. Please report this on GitHub, along with a description of whatever steps are necessary to reproduce this. Thank you!",
	};
}


method scenes () {
	@scenes
}


method name () {
	$name
}


# name without soft hyphens, which can cause issues in <title> for some clients
method title () {
	$name =~ s/\xad//gr
}


method summary () {
	$summary
}


method choices () {
	$choices
}


method lines_for_choice ($id) {
	return unless $choices->{$id} && $choices->{$id}->{lines};
	return $choices->{$id}{lines}->@*;
}


method lines_for_scene ($scene) {
	return unless $scenes[$scene];
	return $scenes[$scene]->@*;
}


my %TEXT = (
	choice   => "Offer choices.",
	fadein   => "Fade in clock.",
	fadeout  => "Fade out clock.",
	newscene => "New scene.",
	success  => "Show mission success screen.",
);


method lines_singlepage () {
	my @lines;
	for my $scene (@scenes) {
		push @lines, {
			action => 1,
			class  => "action line",
			text   => $TEXT{newscene},
		};
		
		LINE:
		for my $line ($scene->@*) {
			if (ref $line ne 'HASH') {
				push @lines, {
					class => "line",
					text  => $line,
				};
				next LINE;
			}
			
			my $action = {
				action => 1,
				class  => "action line",
				text   => "Action: " . ($TEXT{$line->{event} // ''} // $line),
			};
			push @lines, $action;
			push @lines, {
				class => "line",
				text  => $line->{text},
			} if $line->{text};
			
			next LINE unless $line->{choice};
			$action->{text} = "Action: " . $TEXT{choice};
			$action->{list} = [ map { $choices->{$_}{name} } $line->{choice}->@* ];
			
			next LINE unless $line->{singlepage};
			for my $choice ($line->{choice}->@*) {
				push @lines, {
					action => 1,
					class  => "action line",
					text   => "Choice: " . $choices->{$choice}{name},
				};
				push @lines, map {{
					class => "line",
					text  => $_,
				}} $self->lines_for_choice($choice);
			}
		}
	}
	return \@lines;
}
