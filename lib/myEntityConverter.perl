#!/usr/bin/perl5

%char2myentity=();
%myentity2char=();
%htmlentity2char=();

%htmlentity2char = (

	amp		=> "\x20",			# mapped to space
	'gt'	=> "\x20",			# mapped to space
	'lt'	=> "\x20",			# mapped to space
	quot	=> "\x20",			# mapped to space

	nbsp	=>	"\xa0",
	iexcl	=>	"\xa1",
	cent	=>	"\xa2",
	pound	=>	"\xa3",
	curren	=>	"\xa4",
	yen		=>	"\xa5",
	brvbar	=>	"\xa6",
	sect	=>	"\xa7",
	uml		=>	"\xa8",
	copy	=>	"\xa9",
	ordf	=>	"\xaa",
	laquo	=>	"\xab",
	'not'	=>	"\xac",
	shy		=>	"\xad",
	reg		=>	"\xae",
	macr	=>	"\xaf",
	deg		=>	"\xb0",
	plusmn	=>	"\xb1",
	sup2	=>	"\xb2",
	sup3	=>	"\xb3",
	acute	=>	"\xb4",
	micro	=>	"\xb5",
	para	=>	"\xb6",
	middot	=>	"\xb7",
	cedil	=>	"\xb8",
	sup1	=>	"\xb9",
	ordm	=>	"\xba",
	raquo	=>	"\xbb",
	frac14	=>	"\xbc",
	frac12	=>	"\xbd",
	frac34	=>	"\xbe",
	iquest	=>	"\xbf",
	Agrave	=>	"\xc0",
	Aacute	=>	"\xc1",
	Acirc	=>	"\xc2",
	Atilde	=>	"\xc3",
	Auml	=>	"\xc4",
	Aring	=>	"\xc5",
	AElig	=>	"\xc6",
	Ccedil	=>	"\xc7",
	Egrave	=>	"\xc8",
	Eacute	=>	"\xc9",
	Ecirc	=>	"\xca",
	Euml	=>	"\xcb",
	Igrave	=>	"\xcc",
	Iacute	=>	"\xcd",
	Icirc	=>	"\xce",
	Iuml	=>	"\xcf",
	ETH		=>	"\xd0",
	Ntilde	=>	"\xd1",
	Ograve	=>	"\xd2",
	Oacute	=>	"\xd3",
	Ocirc	=>	"\xd4",
	Otilde	=>	"\xd5",
	Ouml	=>	"\xd6",
	'times'	=>	"\xd7",
	Oslash	=>	"\xd8",
	Ugrave	=>	"\xd9",
	Uacute	=>	"\xda",
	Ucirc	=>	"\xdb",
	Uuml	=>	"\xdc",
	Yacute	=>	"\xdd",
	THORN	=>	"\xde",
	szlig	=>	"\xdf",
	agrave	=>	"\xe0",
	aacute	=>	"\xe1",
	acirc	=>	"\xe2",
	atilde	=>	"\xe3",
	auml	=>	"\xe4",
	aring	=>	"\xe5",
	aelig	=>	"\xe6",
	ccedil	=>	"\xe7",
	egrave	=>	"\xe8",
	eacute	=>	"\xe9",
	ecirc	=>	"\xea",
	euml	=>	"\xeb",
	igrave	=>	"\xec",
	iacute	=>	"\xed",
	icirc	=>	"\xee",
	iuml	=>	"\xef",
	eth		=>	"\xf0",
	ntilde	=>	"\xf1",
	ograve	=>	"\xf2",
	oacute	=>	"\xf3",
	ocirc	=>	"\xf4",
	otilde	=>	"\xf5",
	ouml	=>	"\xf6",
	divide	=>	"\xf7",
	oslash	=>	"\xf8",
	ugrave	=>	"\xf9",
	uacute	=>	"\xfa",
	ucirc	=>	"\xfb",
	uuml	=>	"\xfc",
	yacute	=>	"\xfd",
	thorn	=>	"\xfe",
	yuml	=>	"\xff"

);


for( 0..255 )
{
	if( $_ < 0xA0 )
	{
		# $char2myentity{chr($_)}=chr($_);
	}
	else
	{
		if( ($_>= 0xA0)  && ($_<=0xAF) ) {$prefix='A';};
		if( ($_>= 0xB0)  && ($_<=0xBF) ) {$prefix='a';};
		if( ($_>= 0xC0)  && ($_<=0xCF) ) {$prefix='B';};
		if( ($_>= 0xD0)  && ($_<=0xDF) ) {$prefix='C';};
		if( ($_>= 0xE0)  && ($_<=0xEF) ) {$prefix='b';};
		if( ($_>= 0xF0)  && ($_<=0xFF) ) {$prefix='c';};
		$number = $_%0x10;
		$number = '0'.$number if $number < 10;
		$char2myentity{chr($_)}='&'.$prefix.$number.';';
		$myentity2char{$prefix.$number}=chr($_);						# reverse mapping
	}
}



sub decode_entities
{
    for (@_)
	{
		s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
		s/(&(\w+);?)/$htmlentity2char{$2} || $1 /eg;
		s/(&([ABCabc]{1}\d{2});)/$myentity2char{$2} || $1/eg;
    }
    $_[0];
}

sub encode_entities
{
    if (defined $_[1])
	{
		unless (exists $subst{$_[1]})
		{
	    	# Because we can't compile regex we fake it with a cached sub
	    	$subst{$_[1]} =  eval "sub {\$_[0] =~ s/([$_[1]])/\$char2myentity{\$1}/g; }";
	    	die $@ if $@;
		}
		&{$subst{$_[1]}}($_[0]);
    } 
	else
	{
		# Encode control chars, high bit chars and '<', '&', '>', '"'
		$_[0] =~ s/([^\n\t !#$%'-;=?-~])/$char2myentity{$1}/g;
    }
    $_[0];
}

1;