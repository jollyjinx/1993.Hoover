#!/bin/perl

open(FILE,"| perl5 ~/Diplom/converter/iso2mycoding.perl |tr A-Z a-z |perl5 ~/Diplom/converter/mycoding2iso.perl");

while(<>)
{
	print FILE $_;
}
close(FILE);