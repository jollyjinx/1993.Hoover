#!/usr/bin/perl


require "myEntityConverter.perl";
while(<>)
{
	&encode_entities($_);
	print $_;
}
