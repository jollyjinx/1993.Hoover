#
#	WWW proxycache fill
#
#

use GDBM_File;

dbmopen(%bigramm,'bigramm.gdbm',0644) || die "can't open dbm\n";

# shift @ARGV;
while( $ask = shift(@ARGV) )
{
	print $ask.' written in :'.$bigramm{$ask}."\n";
}

dbmclose(%bigramm);

exit;
