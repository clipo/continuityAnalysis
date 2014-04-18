use strict;
use Data::Dumper;
my $file = $ARGV[0];
open (FILE,"$ARGV[0]") or die "Can't open file $ARGV[0].";
my $outtxt = $ARGV[0];
open OUTFILE, ">$outtxt.vna";
print OUTFILE "*tie data\n";
my @listOfLinks;
my @listOfPairs;
my ($firstflag, $secondflag, $firstlist, $secondlist, $samelistflag);

## first time through - create the first list with the first pair
my $firsttimethrough=1;
my $firsttimepair = "dummy1-dummy2";
push(@listOfLinks, $firsttimepair);
my $numlinks=1;
my %valuelist;

my $oldval =0;
my $valchange=0;
my $templist;
while (<FILE>)
{
	my $line =$_;
	chomp($line);
	my ($name1, $name2, $val) = split("\t", $line);
	my $firstadded=0; 
	my $secondadded=0;
	if ($val != $oldval) {
		$valchange =1;
		$oldval = $val;
		$templist = "";
	} else {
		$valchange=0;
	}
	#print "Value is: $val\n";
	#print "Valchange flag is $valchange\n";
	#print "list is: $templist\n";
	$firstflag=$secondflag=0;
	$firstlist=$secondlist='';
	#print "------------------------------------------------------\n ";
	#print "FIRST: checking for $name1 and $name2 with value: $val\n";
	# now find which list they are on....
	#print "Current list length: $numlinks\n";
	#	print "Current list ", Dumper(@listOfLinks), "\n";

	for (my $i=0; $i< $numlinks+1; $i++) {
		##print "first loop through looking for instance of name on lists\n";			
		my $currlist = $listOfLinks[ $i];
	
		if (grep(/$name1/i, $currlist ) ) {
			# test to see if there are 
			$firstlist = $currlist;
			$firstflag=$i; ## name on first list
			#print "name1: $name1 is on list #$i: ", $firstlist, "\n";
		}
		if (grep(/$name2/i,$currlist) ) {
			$secondlist =  $currlist ;
			$secondflag=$i; ## name on second list
			#print "$secondflag  name2: $name2 is on list #$i : ", $secondlist, "\n";
		}
		if (($firstflag && $secondflag) && ($firstlist eq $secondlist)  ) {
			#print "Warning!!!: Same List!!!\n";
			$samelistflag = 1;
		}
				
		##print "endloop\n";
	}
	

	if (!$samelistflag  ) { 

	
		if( !$firstflag && !$secondflag ) { 
			## now deal with the case where name1 is NOT listed anywhere
			# this should result in a new list 
			##print "name1: $name1 and name2: $name2 not on lists -- adding!\n";
			my $newList = $name1."-".$name2;

			push (@listOfLinks, $newList );
			$numlinks++;	
	
			##print "This is a *new* list: ", $newList, "\n";
			###print "This is the current list of lists: ", Dumper(@listOfLinks), "\n";
			##print "This list is now $numlinks long\n";
	
			push( @listOfPairs, $line);
			$templist .= $name1."-".$name2."-";
	
			## first check and see if the first or second name is listed in any list anywhere
		} elsif  ($firstflag || $secondflag ) {
		
			if ($firstflag && $secondflag )  {
				## if they both exist but are not on the same list 
				## then we need to merge the lists;
			

			##print "Found $name1 on list $firstflag \n";
			##print "Found $name2 on list $secondflag \n";
			##print "Merging lists \n";
			##print "first: ",$firstlist,"\n";
			##print "second: ",$secondlist,"\n";
			my $newList = $firstlist. "-". $secondlist;
			@listOfLinks[ $firstflag ] = "";
			@listOfLinks[ $secondflag ] = "";
			push(@listOfLinks, $newList);
			$numlinks++; ### increment the number of links;
			##print "New List is now : ", $newList,"\n";
			#dont bother doing the other things
			push(@listOfPairs, $line);
			$templist .= $name1."-".$name2."-";


			} elsif  ($firstflag  && !$secondflag)   {	
			
			##print "firstname: $name1 on list # $firstflag \n";
			##print "secondname: $name2 not found\n";
			##print "adding to list\n";
			$firstlist .= "-".$name2;
			@listOfLinks[$firstflag] = $firstlist;
			push(@listOfPairs, $line);
			$secondadded=1;
			$templist .= $name1."-".$name2."-";
		
			} elsif (!$firstflag  && $secondflag ){
			##print "secondname: $name2 on list # $secondflag\n";
			##print "firstname: $name1 not found\n";
			##print "adding name to list\n";	
			$secondlist .= "-".$name1;
			@listOfLinks[$secondflag] = $secondlist;
			push(@listOfPairs, $line);	
			$firstadded =1;
			$templist .= $name1."-".$name2."-";

			}
		}		
			
	}		
	if (($firstflag && $secondflag) && (grep(/$name1/i, $templist) || grep(/$name2/i,$templist)) ) {
		
#			print "templist is $templist\n";
#			print "val is $val\n";
#			print "valchange is $valchange\n";	
			push(@listOfPairs, $line);
		}

	if ($firsttimethrough) {
		push(@listOfPairs,$line);
		$firsttimethrough=0;
	}
##	##print Dumper(@listOfLists);
	$firstflag=$secondflag=$samelistflag=0;
	$firstlist=$secondlist="";
}

foreach my $line (@listOfPairs) {
	print OUTFILE $line,"\n";
}		 	 	
close FILE;

close OUTFILE;
