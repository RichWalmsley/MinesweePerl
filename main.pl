#!usr/bin/perl
use strict;
use warnings;

use Term::Cap;

my $terminal = Term::Cap->Tgetent( {OSPEED => 9600} );
my $clear_string = $terminal->Tputs('cl');

use constant {
	WIDTH => 9,
	HEIGHT => 9,
	MINES => $ARGV[0],
};

use constant {
	EMPTY => 0,
	MINE => 9,
};

my @map = ('▓')x(WIDTH*HEIGHT);
my @minefield = (EMPTY)x(WIDTH*HEIGHT);
my $frame = "";
my $DRAWFLAG = 1;
my $EXITFLAG = 0;
my $WINFLAG = 0;
my $LOSEFLAG = 0;

my $mines_placed = 0;
my $squares_cleared = 0;

sub clear{
	print $clear_string;
}

# put the map into a frame buffer
sub draw{
	$frame = $frame."  ";
	
	for (my $width = 0; $width < WIDTH; $width++){
		$frame = $frame.$width;
	}
	
	$frame = $frame."\n\n";

	for(my $y = 0; $y < HEIGHT; $y++){
		$frame = $frame.$y." ";
		for(my $x = 0; $x < WIDTH; $x++){
			$frame = $frame.@map[$x+($y*HEIGHT)];
		}
		$frame = $frame."\n";
	}
	
	print $frame;
	$frame = '';
}

# process clicking
sub click{
	my ($x, $y) = @_;
	
	print "Clicked (", $x, ",", $y, ")\n";
	
	if(@minefield[$x+($y*HEIGHT)] eq MINE){
		@map[$x+($y*HEIGHT)] = 'X';
		$DRAWFLAG = 1;
		$LOSEFLAG = 1
	}
	elsif(@minefield[$x+($y*HEIGHT)] != MINE){	
		@map[$x+($y*HEIGHT)] = @minefield[$x+($y*HEIGHT)];
		reveal();
		checkWin();
		if ($squares_cleared eq WIDTH * HEIGHT - MINES){
			$WINFLAG = 1;
		}
		$DRAWFLAG = 1;
	}
}

sub checkAdjacent{
	my ($x, $y) = @_;
	
	for (my $j = $y - 1; $j <= $y + 1; $j++){
		next if ($j < 0 || $j >= HEIGHT);
		for (my $i = $x - 1; $i <= $x + 1; $i++){
			next if ($i < 0 || $i >= WIDTH);
			next if (@minefield[$i+($j*HEIGHT)] == MINE);
			
			@map[$i+($j*HEIGHT)] = @minefield[$i+($j*HEIGHT)];
		}
	}
}

sub reveal{
	for (my $y = 0; $y < HEIGHT; $y++){
		for (my $x = 0; $x < WIDTH; $x++){
			if (@minefield[$x+($y*HEIGHT)] == MINE){
				last;
			}
			
			if (@map[$x+($y*HEIGHT)] eq @minefield[$x+($y*HEIGHT)]){
				checkAdjacent($x, $y);
			}
		}
	}
}

sub checkWin{
	my $squares_checked = 0;

	for (my $y = 0; $y < HEIGHT; $y++){
		for (my $x = 0; $x < WIDTH; $x++){			
			if (@map[$x+($y*HEIGHT)] eq @minefield[$x+($y*HEIGHT)]){
				$squares_checked++;
			}
		}
	}
	
	$squares_cleared = $squares_checked;
}

# handle any command given for clicking blocks
sub inputHandle{
	my ($input) = @_;
	
	my @command = split(' ', $input);
	
	if ($command[0] eq 'click' && $#command eq 2){
		click($command[1], $command[2]);
	}
	else{
		print "ERROR: Command not understood.\n";
	}
}

# place mines
while ($mines_placed < MINES){

	my $x = int(rand WIDTH);
	my $y = int(rand HEIGHT);
	
	if (@minefield[$x+($y*HEIGHT)] eq EMPTY){
		@minefield[$x+($y*HEIGHT)] = MINE;
		$mines_placed++;
	}
}

# calculate numbers
for (my $y = 0; $y < HEIGHT; $y++){
	for (my $x = 0; $x < WIDTH; $x++){
		next if (@minefield[$x+($y*HEIGHT)] == MINE);
		
		my $mines_adjacent = 0;
		
		for (my $j = $y - 1; $j <= $y + 1; $j++){
			next if ($j < 0 || $j >= HEIGHT);
			for (my $i = $x - 1; $i <= $x + 1; $i++){
				next if ($i < 0 || $i >= WIDTH);
				
				if (@minefield[$i+($j*HEIGHT)] == MINE){
					$mines_adjacent++;
				}
			}
		}
		
		@minefield[$x+($y*HEIGHT)] = $mines_adjacent;
	}
}

while(1){
	if($DRAWFLAG){
		clear();
		draw();
		$DRAWFLAG = 0;
	}
	
	if($WINFLAG){
		print "YOU WIN!\n";
		last;
	}
	elsif($LOSEFLAG){
		print "BOOM! YOU LOSE!\n";
		last;
	}
	
	my $command = <STDIN>;
	inputHandle($command);
}