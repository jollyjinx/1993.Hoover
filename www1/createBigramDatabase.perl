#
#	WWW proxycache fill
#
#

use GDBM_File;
use HTML::Entities;

dbmopen(%bigramm,'bigramm.gdbm',0644) || die "can't open dbm\n";

# %bigramm = ( );

while(<>)
{
	# chop;
	($countries,$readbigramm) = split(/\s+/);
	$readbigramm = encode_entities(decode_entities($readbigramm));
	if( !$bigramm{$readbigramm} )
	{
		$bigramm{$readbigramm} = $countries;
		printf("NEW String:%40s %-25s\n",$readbigramm,$bigramm{$readbigramm});
	}
	else
	{
		
		@newcountries = split(/(\d+)/,$countries);
		shift @newcountries;
		shift @newcountries;
		
		
		while( ($country,$count)=splice(@newcountries,0,2) )
		{
			$_ = $bigramm{$readbigramm};
			if( /^(\d+)(.*)$country(\d+)(.*)$/ )
			{
				$all = $1+$count;
				$local = $3+$count;
				
				$bigramm{$readbigramm} = $all.$2.$country.$local.$4;
			}
			else
			{
				/^(\d+)(.*)$/;
				$bigramm{$readbigramm} = $1+$count.$2.$country.$count;
			}
		}
		
		printf("    String:%40s %-25s\n",$readbigramm,$bigramm{$readbigramm});
	}
	
}

dbmclose(%bigramm);

exit;
