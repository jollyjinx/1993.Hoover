#!/usr/bin/perl5
#
#	name	:	broadsearch.perl
#	author	:	Patrick Stein <jolly@joker.de>
#	version	:	not released yet
#
#
require 5.002;

use JWO::Page;


$program{'version'}		= 0.01;
$program{'name'}		= 'broadsearch';


# Create a request
$page =  JWO::Page->newWithUrl('http://www.leo.org/',5);
$response = $page->get();

if ($response == 200) 
{
	@l=$page->links();
	push(@l,'bla');
	print 'Links :'.join(' ',@l)."\n";
	print 'Contents'.$page->contents()."\n";
}
else 
{
	print "Bad luck this time\n";
}
