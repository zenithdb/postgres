
# Copyright (c) 2021-2024, PostgreSQL Global Development Group

# src/pl/plperl/text2macro.pl

=head1 NAME

text2macro.pl - convert text files into C string-literal macro definitions

=head1 SYNOPSIS

  text2macro [options] file ... > output.h

Options:

  --prefix=S   - add prefix S to the names of the macros
  --name=S     - use S as the macro name (assumes only one file)

=head1 DESCRIPTION

Reads one or more text files and outputs a corresponding series of C
pre-processor macro definitions. Each macro defines a string literal that
contains the contents of the corresponding text file. The basename of the text
file is capitalized and used as the name of the macro, along with an optional prefix.

=cut

use strict;
use warnings FATAL => 'all';

use Getopt::Long;

GetOptions(
	'prefix=s' => \my $opt_prefix,
	'name=s' => \my $opt_name,
	'selftest!' => sub { exit selftest() },) or exit 1;

# This was once a command-line option, but meson is obstreperous
# about passing backslashes through custom targets.
my $opt_strip = '^(#.*|\s*)$';

die "No text files specified"
  unless @ARGV;

print qq{
/*
 * DO NOT EDIT - THIS FILE IS AUTOGENERATED - CHANGES WILL BE LOST
 * Generated by src/pl/plperl/text2macro.pl
 */
};

for my $src_file (@ARGV)
{

	(my $macro = $src_file) =~ s/ .*? (\w+) (?:\.\w+) $/$1/x;

	open my $src_fh, '<', $src_file
	  or die "Can't open $src_file: $!";

	printf qq{#define %s%s \\\n},
	  $opt_prefix || '',
	  ($opt_name) ? $opt_name : uc $macro;
	while (<$src_fh>)
	{
		chomp;

		next if $opt_strip and m/$opt_strip/o;

		# escape the text to suite C string literal rules
		s/\\/\\\\/g;
		s/"/\\"/g;

		printf qq{"%s\\n" \\\n}, $_;
	}
	print qq{""\n\n};
}

print "/* end */\n";

exit 0;


sub selftest
{
	my $tmp = "text2macro_tmp";
	my $string = q{a '' '\\'' "" "\\"" "\\\\" "\\\\n" b};

	open my $fh, '>', "$tmp.pl" or die;
	print $fh $string;
	close $fh;

	system("perl $0 --name=X $tmp.pl > $tmp.c") == 0 or die;
	open $fh, '>>', "$tmp.c" or die;
	print $fh "#include <stdio.h>\n";
	print $fh "int main() { puts(X); return 0; }\n";
	close $fh;
	system("cat -n $tmp.c") == 0 or die;

	system("make $tmp") == 0 or die;
	open $fh, '<', "./$tmp |" or die;
	my $result = <$fh>;
	unlink <$tmp.*>;

	warn "Test string: $string\n";
	warn "Result     : $result";
	die "Failed!" if $result ne "$string\n";
	return;
}
