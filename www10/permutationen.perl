#!/usr/bin/perl

$original = shift(@ARGV);
$faelschung = shift(@ARGV);


open(ORIGINAL,$original) || die "Can't open original\n";
while( $_ = <ORIGINAL>)
{
	chop;
	$originalwortliste{$_} = 1;
}
close(ORIGINAL);

open(FALSCH,$faelschung) || die "Can't open faelschung\n";
while( $_ = <FALSCH>)
{
	chop;
	if( /\&/ )
	{
		if( $originalwortliste{$_} )
		{
			print $_."\n";
		}
		else
		{
			@ersetzungen=( "&ouml;","&uuml;","&ucirc;","&eacute;","" );
			@teilworte = split(/&eacute;/);


			@counter=();			
			$carry=0;
			while( !$carry )
			{
				$newword = '';
				foreach $i ( 0..$#teilworte )
				{
					$newword .= $teilworte[$i];
					$newword .= @ersetzungen[$counter[$i]];
				}
				
				# print STDERR "NEWWORD:@counter $newword\n";

				$carry=1;
				foreach $i ( 0..$#teilworte )
				{
					$nextcarry = 0;
					if( $counter[$i] == $#ersetzungen && $carry )
					{
					 	$nextcarry =1;
					}
					$counter[$i]= ( (1+$counter[$i]) % ($#ersetzungen+1) ) if $carry;
					$carry = $nextcarry;
				}
				
				if( $originalwortliste{$newword} )
				{
					print $newword."\n";
					$carry=1;
				}
			} 
			
			
			if( !$originalwortliste{$newword} )
			{
				print STDERR "WRONG".$_."\n";
			}
		}
	}
	else
	{
		if( $originalwortliste{$_} )
		{
			print $_."\n";
		}
		else
		{
			print STDERR "WRONG2".$_."\n";
		}
	}
}
close(FALSCH);

