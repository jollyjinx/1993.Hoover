#!/usr/bin/perl5
#
#	name	:	JWO::Page.pm
#	author	:	Patrick Stein <jolly@joker.de>
#	version	:	not released yet
#
#

require "wwwbot.pl";
require "wwwhtml.pl";

package JWO::Page;

sub version		{return '1';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@joker.de>'};
sub date		{return 'Thu Sep 19 12:42:56 MET DST 1996'};

sub newWithUrl
{
	my($class,$url,$timeout) = @_;
	my $self = bless {};
	$self->{url}		= $url;
	$self->{timeout}	= $timeout;
	return $self;
}

sub get
{
	my($self) = @_;
	my @links;
	
	my $response = &www'request('GET',$self->{'url'},*headers,*contents,$self->{'timeout'});
	
	$contents =~ s{<\/?( A| H1| H2| H3| H4| EM| STRONG| BR)+>}{}gix;
	$contents =~ s/<a\s+href= ([^>'"]*|".*?"|'.*?')>/push(@links,$1);'';/giex;
	$contents =~ s{ < (.*) ([^>'"] * | ".*?"  |  '.*?') > }{ HTMLCOMMAND }gx;
	$self->{'contents'} = \contents;
	$self->{'links'}= \@links;
	return $response;
}

sub contents
{
	my($self) = @_;
	return  $self->{'contents'};
}

sub links
{
	my($self) = @_;
	return $self->{'links'};
}








%entity2char = (

# Entities we don't need are mapped to SPACE except for 'nbsp which is mapped to ''
 amp    => ' ',  # ampersand 
'gt'    => ' ',  # greater than
'lt'    => ' ',  # less than
 quot   => ' ',  # double quote

 copy   => ' ',  # copyright sign
 reg    => ' ',  # registered sign
 nbsp   => '',	 # non breaking space

 iexcl  => ' ',
 cent   => ' ',
 pound  => ' ',
 curren => ' ',
 yen    => ' ',
 brvbar => ' ',
 sect   => ' ',
 uml    => ' ',
 ordf   => ' ',
 laquo  => ' ',
'not'   => ' ',    # not is a keyword in perl
 shy    => ' ',
 macr   => ' ',
 deg    => ' ',
 plusmn => ' ',
 sup1   => ' ',
 sup2   => ' ',
 sup3   => ' ',
 acute  => ' ',
 micro  => ' ',
 para   => ' ',
 middot => ' ',
 cedil  => ' ',
 ordm   => ' ',
 raquo  => ' ',
 frac14 => ' ',
 frac12 => ' ',
 frac34 => ' ',
 iquest => ' ',
'times' => ' ',    # times is a keyword in perl
 divide => ' ',

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> 'Æ',  # capital AE diphthong (ligature)
 Aacute	=> 'Á',  # capital A, acute accent
 Acirc	=> 'Â',  # capital A, circumflex accent
 Agrave	=> 'À',  # capital A, grave accent
 Aring	=> 'Å',  # capital A, ring
 Atilde	=> 'Ã',  # capital A, tilde
 Auml	=> 'Ä',  # capital A, dieresis or umlaut mark
 Ccedil	=> 'Ç',  # capital C, cedilla
 ETH	=> 'Ð',  # capital Eth, Icelandic
 Eacute	=> 'É',  # capital E, acute accent
 Ecirc	=> 'Ê',  # capital E, circumflex accent
 Egrave	=> 'È',  # capital E, grave accent
 Euml	=> 'Ë',  # capital E, dieresis or umlaut mark
 Iacute	=> 'Í',  # capital I, acute accent
 Icirc	=> 'Î',  # capital I, circumflex accent
 Igrave	=> 'Ì',  # capital I, grave accent
 Iuml	=> 'Ï',  # capital I, dieresis or umlaut mark
 Ntilde	=> 'Ñ',  # capital N, tilde
 Oacute	=> 'Ó',  # capital O, acute accent
 Ocirc	=> 'Ô',  # capital O, circumflex accent
 Ograve	=> 'Ò',  # capital O, grave accent
 Oslash	=> 'Ø',  # capital O, slash
 Otilde	=> 'Õ',  # capital O, tilde
 Ouml	=> 'Ö',  # capital O, dieresis or umlaut mark
 THORN	=> 'Þ',  # capital THORN, Icelandic
 Uacute	=> 'Ú',  # capital U, acute accent
 Ucirc	=> 'Û',  # capital U, circumflex accent
 Ugrave	=> 'Ù',  # capital U, grave accent
 Uuml	=> 'Ü',  # capital U, dieresis or umlaut mark
 Yacute	=> 'Ý',  # capital Y, acute accent
 aacute	=> 'á',  # small a, acute accent
 acirc	=> 'â',  # small a, circumflex accent
 aelig	=> 'æ',  # small ae diphthong (ligature)
 agrave	=> 'à',  # small a, grave accent
 aring	=> 'å',  # small a, ring
 atilde	=> 'ã',  # small a, tilde
 auml	=> 'ä',  # small a, dieresis or umlaut mark
 ccedil	=> 'ç',  # small c, cedilla
 eacute	=> 'é',  # small e, acute accent
 ecirc	=> 'ê',  # small e, circumflex accent
 egrave	=> 'è',  # small e, grave accent
 eth	=> 'ð',  # small eth, Icelandic
 euml	=> 'ë',  # small e, dieresis or umlaut mark
 iacute	=> 'í',  # small i, acute accent
 icirc	=> 'î',  # small i, circumflex accent
 igrave	=> 'ì',  # small i, grave accent
 iuml	=> 'ï',  # small i, dieresis or umlaut mark
 ntilde	=> 'ñ',  # small n, tilde
 oacute	=> 'ó',  # small o, acute accent
 ocirc	=> 'ô',  # small o, circumflex accent
 ograve	=> 'ò',  # small o, grave accent
 oslash	=> 'ø',  # small o, slash
 otilde	=> 'õ',  # small o, tilde
 ouml	=> 'ö',  # small o, dieresis or umlaut mark
 szlig	=> 'ß',  # small sharp s, German (sz ligature)
 thorn	=> 'þ',  # small thorn, Icelandic
 uacute	=> 'ú',  # small u, acute accent
 ucirc	=> 'û',  # small u, circumflex accent
 ugrave	=> 'ù',  # small u, grave accent
 uuml	=> 'ü',  # small u, dieresis or umlaut mark
 yacute	=> 'ý',  # small y, acute accent
 yuml	=> 'ÿ',  # small y, dieresis or umlaut mark

);
