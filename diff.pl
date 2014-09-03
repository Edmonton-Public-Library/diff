#!/usr/bin/perl -w
#################################################################################################
# Purpose: Diff files with logical operators. The script returns a minimized list of differences 
#          that is the returned list is sorted (alpha-numerically), without 
#          duplicates.
# Compares two files using binary operators 'and', 'or', and 'not'.
#    Copyright (C) 2014  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Method:  Use reduced boolean algerbra set to diff files.
#
# TODO:    This script does not respect operator precedence (not, and, or) ordering yet
#          and has not implemented parenthesis yet. 
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Date:    September 10, 2012
# Rev:     0.2 - Added selectable columns from second file.
# Rev:     0.1 - Added trim function for removing end of line whitespace.
# Rev:     0.0 - Dev.
###################################################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;

my $VERSION        = "0.2";
my @COLUMNS_WANTED = ();

#
# Message about this program and how to use it
#
sub usage()
{
    print STDERR << "EOF";

	usage: [echo "f1.txt <operator> f2.txt" |] $0 [-xdiot] [-f<c0,c1,...,cn>]
This script allows the user to specify differences in files by boolean algerbra.
Example: echo "file1.txt or file2.txt" | diff.pl would output the contents of both files.
Example: echo "file1.txt and file2.txt" | diff.pl would output lines that match both files.
         echo "file1.txt not file2.txt" | diff.pl outputs lines from file1.txt that are not in file2.txt
 -d            : Print debug information.
 -i            : Ignore letter casing.
 -f[c1,c2,c3,...cn]: Columns from file 2 to be ignored on comparison. If the columns doesn't exist it is ignored.
 -o            : Order all input file contents first.
 -t            : Force a trailing delimiter or '|' at the end of the line when -f is used.
 -x            : This (help) message.

example: $0 -x
example: echo "file1.lst and file2.lst" | $0 -fc2,c3,c4 
         which would report the difference of file1.lst and file2.lst, ignoreing values in file2.lst in 
         columns 2,3, and 4 (if present).
Version: $VERSION
EOF
    exit;
}

# Kicks off switch setting.
# param:  
# return: 
sub init
{
    my $opt_string = 'df:iotx';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
	if ( $opt{'f'} )
	{
		# Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
		$opt{'f'} .= "," if ( $opt{'f'} !~ m/,/ );
		my @cols = split( ',', $opt{'f'} );
		foreach my $colNum ( @cols )
		{
			# Columns are designated with 'c' prefix to get over the problem of perl not recognizing 
			# '0' as a legitimate column number.
			if ( $colNum =~ m/c\d{1,}/ )
			{
				$colNum =~ s/c//; # get rid of the 'c' because it causes problems later.
				push( @COLUMNS_WANTED, trim($colNum) );
			}
		}
		if ( scalar @COLUMNS_WANTED == 0 )
		{
			print STDERR "**Error, '-f' flag used but no valid columns selected.\n";
			usage();
		}
	}
	print STDERR "columns requested from second file: '@COLUMNS_WANTED'\n" if ( $opt{'d'} and $opt{'f'} );
	my $sentence = <>;
	# legal tokens are 'and', 'or', 'not', 'AND', 'OR', or 'NOT' <file name>.
	my @tokens   = split( /\s/, $sentence );
	my $lhs = parse( @tokens );
	for my $result ( sort keys %$lhs )
	{
		print "$result\n" if ( $result );
	}
}

#
# Trim function to remove whitespace from the start and end of the string.
# param:  string to trim.
# return: string without leading or trailing spaces.
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

init();

# Returns a list of items anded from LHS and RHS.
# param:  
# return: list of items.
sub sOr
{
	my ( $tmp_lhs, $tmp_rhs ) = @_;
	my $tmp;
	for my $key ( keys %$tmp_lhs )
	{
		$tmp->{ $key } = 1;
	}
	for my $key ( keys %$tmp_rhs )
	{
		$tmp->{ $key } = 1;
	}
	return $tmp;
}

# Returns a list of uniq items that are in LHS or RHS.
# param:  
# return: list of items.
sub sAnd
{
	my ( $tmp_lhs, $tmp_rhs ) = @_;
	my $tmp;
	for my $key ( keys %$tmp_lhs )
	{
		$tmp->{ $key } = 1 if ( $tmp_lhs->{ $key } and $tmp_rhs->{ $key } );
	}
	return $tmp;
}

# Could have named this better, but returns a list of items from LHS that are not in RHS
# param:  
# return: list of items.
sub sNot
{
	my ( $tmp_lhs, $tmp_rhs ) = @_;
	my $tmp;
	for my $key ( keys %$tmp_lhs )
	{
		$tmp->{ $key } = 1 if ( not $tmp_rhs->{ $key } );
	}
	return $tmp;
}

#
# Performs the operation designated by arguments on left hand side and right hand side lists.
# param:  operation string - either 'and', 'or', or 'not'.
# return: list after the operation has completed.
sub doOperation
{
	my ( $lhs, $operation, $rhs ) = @_;
	if ( keys %$lhs == 0 or keys %$rhs == 0 )
	{
		print STDERR "can't complete operation; missing right hand value of operator '$operation'\n";
		exit( 0 );
	}
	return sNot( $lhs, $rhs ) if ( $operation eq "NOT");
	return sAnd( $lhs, $rhs ) if ( $operation eq "AND");
	return sOr( $lhs, $rhs )  if ( $operation eq "OR" );
	print STDERR "Unknown operation '$operation'\n";
	exit( 0 );
}

#
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub getColumns( $ )
{
	my $line = shift;
	my @columns = split( '\|', $line );
	return $line if ( scalar( @columns ) < 2 );
	my @newLine = ();
	foreach my $i ( @COLUMNS_WANTED )
	{
		push( @newLine, $columns[ $i ] ) if ( defined $columns[ $i ] and exists $columns[ $i ] );
	}
	$line = join( '|', @newLine );
	$line .= "|" if ( $opt{'t'} );
	print STDERR ">$line<, " if ( $opt{'d'} );
	return $line;
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
	my @tokens   = @_;
	my $operator = "";
	my $lhs;
	my $rhs;
	while ( @tokens )
	{
		my $token = shift( @tokens );
		if ( $token eq "or" or $token eq "OR" ) # only on FILE or after CLOSE_PAREN
		{
			print STDERR "or: '$token'\n" if ( $opt{'d'} );
			$operator = "OR";
			next;
		}
		elsif ( $token eq "and" or $token eq "AND" ) # only on FILE or after CLOSE_PAREN
		{
			print STDERR "and: '$token'\n" if ( $opt{'d'} );
			$operator = "AND";
			next;
		}
		elsif ( $token eq "not" or $token eq "NOT" ) # only on FILE or after CLOSE_PAREN
		{
			print STDERR "not: '$token'\n" if ( $opt{'d'} );
			$operator = "NOT";
			next;
		}
		# elsif ( $token eq "(" ) # only on INIT or after OPERATOR
		# {
			# print "(: '$token'\n" if ( $opt{'d'} );
			## what to do here? can we call parse recursively?
		# }
		# elsif ( $token eq ")" ) # can only follow FILE
		# {
			# print "): '$token'\n" if ( $opt{'d'} );
			# $lhs = doOperation( $lhs, $operation, $rhs );
		# }
		elsif ( -T $token ) # the token looks like a text file.
		{
			print STDERR "file: '$token'\n" if ( $opt{'d'} );
			open( FILE_IN, "<$token" ) or die "Error reading '$token': $!\n";
			if ( keys %$lhs == 0 )
			{
				while ( <FILE_IN> )
				{
					my $line = trim( $_ ); #chomp;
					$lhs->{ $line } = 1;
				}
				close( FILE_IN );
				next;
			} 
			else # else fill the rh side hash ref.
			{
				while ( <FILE_IN> )
				{
					my $line = trim( $_ ); #chomp;
					$line = getColumns( $line ) if ( $opt{'f'} );
					$rhs->{ $line } = 1;
				}
				close( FILE_IN );
				return doOperation( $lhs, $operator, $rhs );
			}
		}
		else
		{
			print STDERR "Syntax error: unrecognized token '$token'.\n";
			exit( 0 );
		}
	}
	print STDERR "Syntax error: incomplete expression '@tokens'\n";
	exit( 0 );
}

# EOF