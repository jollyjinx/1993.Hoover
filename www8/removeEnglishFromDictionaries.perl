
require "FastRecognizer.pm";
foreach $filename (@ARGV)
{
	$filename =~ s/\.frequency$//;
	push(@filenames,$filename);
}
$recognizer = Recognizer->new();
$recognizer->{'countrydirectory'}='.';
$recognizer->{'countryfileextension'}='frequency';
@countryfiles = @filenames;
$recognizer->{'countryfiles'} = \@countryfiles;
# $recognizer->{'cache'}=1;
$recognizer->buildCache();

open(ENGLISH,">english");
while( $filename = shift(@filenames) )
{
	if( open(FILE,"<$filename.frequency") )
	{
		open(CLEAN,">$filename.noenglish");
		while( $_ = <FILE>)
		{
			if( /^(.*):(\d+)\/(\d+)$/ )
			{
				@words = ($1);
				
				%sorted = $recognizer->recognizeSentence(@words);
				@keys=keys(%sorted);
				if( $#keys > (.9 * $#countryfiles ) )
				{
					print ENGLISH $_;
				}
				else
				{
					print CLEAN $_;
				}
			}
		}
		close(CLEAN);
		close(FILE);
	}
}

close(ENGLISH);