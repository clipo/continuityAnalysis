use strict;
use Spreadsheet::WriteExcel;
use Data::Dumper;

print "First enter input name for file (e.g., input.txt) :";
my $file = <STDIN>;
chomp($file);
open (FILE,$file) or die "Can't open file $file.";

print "Now enter the output name for the file (e.g., output): ";
my $outtxt = <STDIN>;
chomp($outtxt);
open OUTFILE, ">$outtxt";
my $workbook = Spreadsheet::WriteExcel->new("$outtxt.xls");
my $worksheet=$workbook->addworksheet();

print "Are the values separated by (1) nothing, (2) tabs, or (3) spaces (1,2,3, default = 2) : ";
my $separator = <STDIN>;
chomp($separator);
if (!$separator) {
	$separator=2; 
   }

print "Do you want to use (1) 0.5 matching for ? or (0) strict matching where ? are ignored (1, 0, default=0) : ";
my $halfmatchflag = <STDIN>;
chomp($halfmatchflag); 
if (!$halfmatchflag) {
	 $halfmatchflag=0; 
}

my @array;
my $count;
my $length;
my @namearray;
my %hashOfNodes;

print "Do you want to calculate similarity (0) or dissimilarity (1) (1,0, default=0):";
my $dissimilarity = <STDIN>;
chomp($dissimilarity);
if (!$dissimilarity)
 { 
 	$dissimilarity=0; 
 }

while (<FILE>)
{
	my $line =$_;
	chomp($line);
	my ($name, $val);
	$count++;
	if ($separator==1) 
	{
		($name, $val) = split(" ", $line);
		push(@namearray, $name);	
		push(@array, $val);
		print "Name:  ", $name, " Array: ", $val, "\n";
		$length = length($val);
		$worksheet->write($count,0, $name);
		$worksheet->write(0,$count,$name);
	}
	elsif ($separator == 2 || $separator ==3 ) 
	{
		my @valarray;
		if ($separator==2) {	
			@valarray = split("\t", $line);
		} elsif ($separator==3) {
			@valarray = split("\s", $line);
		} 
		push(@namearray, $valarray[0]);
		#print Dumper(@valarray);
		my @newarray;
		for (my $i=1; $i<scalar(@valarray)-1; $i++) {
			$newarray[$i]=$valarray[$i];
			#print "VALUES:  $i -- $newarray[$i] -- $valarray[$i]\n";
		}	
		#print Dumper(@newarray),"\n";		
		push(@array, [ @newarray ]);
		$length=scalar(@newarray);
		#print "SCALAR: $length\n";
		$worksheet->write($count,0, $valarray[0]);
		$worksheet->write(0,$count,$valarray[0]);
	} else {
		print "Error: separator not recognized. \n";
		exit;
	}
	chomp($name);
	#print OUTFILE $name,"\n";
	#print $name, "\n";
}
close FILE;

#outer loop
for (my $m=0; $m<$count; $m++)
{
	my $testname = $namearray[$m];

	for (my $n=$m; $n<$count; $n++)
	{
		my $comparename = $namearray[$n];

		my $score=0;
		if ($separator == 1) { ## case where nosparator
			my $testinstance = $array[$m];
			my $compareinstance = $array[$n];
			for (my $o=0; $o<length($testinstance); $o++)
			{
				my $test = substr($testinstance, $o, 1);
				my $compare =substr($compareinstance, $o, 1);
				print "Comparing :-->$testinstance-->with->$compareinstance\n";
				$score=$score + comparevalues($test, $compare); 
			}
		}
		if ($separator == 2   ) { ## case with tab separator
			my @testinstance = @{$array[$m]} ;	
			my @compareinstance = @{$array[$n]};		
		#	print "Comparing :-->Dumper(@testinstance)-->with->Dumper(@compareinstance)\n";
			for (my $o=0; $o< $length; $o++)
			{
				my $test = $testinstance[$o];
				my $compare = $compareinstance[$o];
				#print "compare $test with $compare\n";
				$score= $score + comparevalues($test,$compare);
			}
		
		}		
		if ($dissimilarity) { $score = ($length)-$score-1; }
		$hashOfNodes {	"$testname#$comparename" } = $score;
		$worksheet->write($n+1,$m+1,$score);
		$score = 0;
	}

}

foreach my $value (sort {$hashOfNodes{$b} <=> $hashOfNodes{$a} } 
           keys %hashOfNodes)
{
	my ($node1, $node2) = split("\#", $value);
	if (!($node1 eq $node2)) {
		print OUTFILE "$node1\t$node2\t$hashOfNodes{ $value }\n"; 
	}
}

close OUTFILE;

print "Now running minmax-network.pl $outtxt\n";
system( "perl", "minmax-network.pl", $outtxt );

sub comparevalues {
	my ($ctest, $ccompare) =  @_;
	my $tempscore = 0;	
	#print "comparing $ctest with $ccompare\n";
	if ($halfmatchflag ==1 && ($ctest eq "?" || $ccompare eq "?")) {
		$tempscore = .5;
	} elsif ($ctest == $ccompare)
	{
		$tempscore = 1;
	}
return $tempscore;
}
