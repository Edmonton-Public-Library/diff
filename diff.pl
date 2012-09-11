#!/usr/bin/perl -w
#################################################################################################
# Purpose: Diff files with logical operators. The script returns a minimized list of differences 
#          that is the returned list is sorted (alpha-numerically), without 
#          duplicates.
# Method:  Use reduced boolean algerbra set to diff files.
#
# TODO:    This script does not respect operator precedence (not, and, or) ordering yet
#          and has not implemented parenthesis yet. 
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Date:    September 10, 2012
# Rev:     0.0 - Dev.
###################################################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;
use Switch;

my @LHS      = ();
my @RHS      = ();

#
# Message about this program and how to use it
#
sub usage()
{
    print STDERR << "EOF";

	usage: $0 [-x]
This script allows the user to specify differences in files by boolean algerbra.
Example: echo "file1.txt or file2.txt" | diff.pl would output the contents of both files.
Example: echo "file1.txt and file2.txt" | diff.pl would output lines that match both files.
         echo "file1.txt not file2.txt" | diff.pl outputs lines from file1.txt that are not in file2.txt
 -d: Print debug information.
 -i: Ignore letter casing.
 -o: Order all input file contents first.
 -x: This (help) message.

example: $0 -x

EOF
    exit;
}

# Kicks off switch setting.
# param:  
# return: 
sub init
{
    my $opt_string = 'diox';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
	my $sentence = <>;
	parse( $sentence );
}
init();

# Returns a list of items anded from LHS and RHS.
# param:  
# return: list of items.
sub sOr
{
	my $tmp;
	while ( @RHS )
	{
		$tmp->{ shift( @RHS ) } = 1;
	}
	while ( @LHS )
	{
		$tmp->{ shift( @LHS ) } = 1;
	}
	return keys %$tmp;
}

# Returns a list of uniq items that are in LHS or RHS.
# param:  
# return: list of items.
sub sAnd
{
	my $tmp_lhs;
	my $tmp_rhs;
	my @tmp = ();
	while ( @RHS )
	{
		$tmp_rhs->{ shift( @RHS ) } = 1;
	}
	while ( @LHS )
	{
		$tmp_lhs->{ shift( @LHS ) } = 1;
	}
	for my $key ( keys %$tmp_lhs )
	{
		push ( @tmp, $key ) if ( $tmp_lhs->{$key} and $tmp_rhs->{$key} );
	}
	return @tmp;
}

# Could have named this better, but returns a list of items from LHS that are not in RHS
# param:  
# return: list of items.
sub sNot
{
	my $tmp_rhs;
	my $tmp_lhs;
	my @tmp = ();
	while ( @RHS )
	{
		$tmp_rhs->{ shift( @RHS ) } = 1;
	}
	while ( @LHS )
	{
		$tmp_lhs->{ shift( @LHS ) } = 1;
	}
	for my $key ( keys %$tmp_lhs )
	{
		push ( @tmp, $key ) if ( not $tmp_rhs->{$key} );
	}
	return @tmp;
}

#
# Performs the operation designated by arguments on left hand side and right hand side lists.
# param:  operation string - either 'and', 'or', or 'not'.
# return: list after the operation has completed.
sub doOperation
{
	my ( $operation ) = @_;
	print "LHS         RHS\n" if ( $opt{'d'} );
	print "@LHS  $operation  @RHS\n" if ( $opt{'d'} );
	switch ( $operation )
	{
		case "NOT" { return sNot( ); }
		case "AND" { return sAnd( ); }
		case "OR"  { return sOr( ); }
		else
		{
			print STDERR "Unknown operation '$operation'\n";
			exit( 0 );
		}
	}
}


#
# Parses the grammer of the input line.
#
# Syntax:
# STATEMENT: ( EXPRESSION ) OPERATOR ( EXPRESSION )
# EXPRESSION: FILE OPERATOR FILE
# OPERATOR: and, or, not
# FILE: text file name
#
# param:  sentence string.
# return: 
sub parse
{
	# legal tokens are '(', ')', 'and', 'or', 'not', <file name>.
	my @tokens   = split( /\s/, $_[0] );
	my $operator = "";
	while (@tokens)
	{
		my $token = shift( @tokens );
		if ( $token eq "or" ) # only on FILE or after CLOSE_PAREN
		{
			print "or: '$token'\n" if ( $opt{'d'} );
			$operator = "OR";
		}
		elsif ( $token eq "and" ) # only on FILE or after CLOSE_PAREN
		{
			print "and: '$token'\n" if ( $opt{'d'} );
			$operator = "AND"; 
		}
		elsif ( $token eq "not" ) # only on FILE or after CLOSE_PAREN
		{
			print "not: '$token'\n" if ( $opt{'d'} );
			$operator = "NOT";
		}
		# elsif ( $token eq "(" ) # only on INIT or after OPERATOR
		# {
			# print "(: '$token'\n" if ( $opt{'d'} );
			## what to do here? can we call parse recursively?
		# }
		# elsif ( $token eq ")" ) # can only follow FILE
		# {
			# print "): '$token'\n" if ( $opt{'d'} );
			# @LHS = doOperation( $operation, @LHS, @RHS );
		# }
		elsif ( -T $token ) # the token looks like a text file.
		{
			print "file: '$token'\n" if ( $opt{'d'} );
			open( FILE_IN, "<$token" ) or die "Error reading '$token': $!\n";
			if ( not @LHS )
			{
				@LHS = <FILE_IN>;
				close( FILE_IN );
				chomp( @LHS );
				next;
			}
			@RHS = <FILE_IN>;
			close( FILE_IN );
			chomp( @RHS );
			@LHS = doOperation( $operator );
		}
		else
		{
			print STDERR "Syntax error: unrecognized token '$token'.\n";
			exit( 0 );
		}
	}
	
	foreach my $result ( sort @LHS )
	{
		print "$result\n" if ( $result );
	}
}

1;
