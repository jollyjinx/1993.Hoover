#!/usr/local/bin/perl5.002

while( $_ = <> )
{
	if( /^(.*):(\d+)\/(\d+)$/ )
	{
		printf "%30s %8.7f %8d %8d\n",$1,100*$2/$3,$2,$3;
	}
}
