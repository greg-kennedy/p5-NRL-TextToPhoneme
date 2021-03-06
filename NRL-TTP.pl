#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;

use List::Util qw( first );
use JSON::PP;

use constant DEBUG => 0;

###
# NRL-TTP.pl - Greg Kennedy 2020
# a Perl implementation of the Naval Research Labs "text-to-IPA" pronunciation
#  by Elovitz, H., Johnson, R., McHugh, A., and Shore, J. (1976)
#  published in IEEE Transactions on Acoustics, Speech and Signal Processing
###

# Parses a rules json, and returns the rules set
my @rules = do {
  # Constants
  #  Character classes used by the NRL rules

  # the NRL paper defines classes for * and $, but these are not actually used
  #  by any of the rules, so they are omitted from the IEEE version
  my %classes = (
    '#' => '[AEIOUY]+',
    #'*' => '[BCDFGHJKLMNPQRSTVWXZ]+',
    '.' => '[BDVGJLMNRWZ]',
    #'$' => '[BCDFGHJKLMNPQRSTVWXZ][EI]',
    '%' => '(?:ER|E|ES|ED|ING|ELY)',
    '&' => '(?:S|C|G|Z|X|J|CH|SH)',
    '@' => '(?:T|S|R|D|L|Z|N|J|TH|CH|SH)',
    '^' => '[BCDFGHJKLMNPQRSTVWXZ]',
    '+' => '[EIY]',
    ':' => '[BCDFGHJKLMNPQRSTVWXZ]*',
  );
  # some regex construction
  my $class_meta = join('', sort keys %classes);

  if (DEBUG) { print STDERR "class_meta is: '$class_meta'\n" }

  my $class_regex = qr/([\Q$class_meta\E])/;
  my $line_regex = qr{^([\Q$class_meta\E A-Z']*)\[([^]]+)\]([\Q$class_meta\E A-Z']*)=(.+)$};

  # get rules file to use
  my $rules_path = $ARGV[0] || 'rules/eng_to_ipa.json';
  if (DEBUG) { print STDERR "Rule file is: '$rules_path'\n" }

  # slurp the file, and pass to decode_json
  my $rules_json = decode_json( do {
    open(my $fh, '<:raw', $rules_path) or die "Failed to open rules: $!";
    local $/;
    <$fh>
  } );

  # the groupings are actually not useful, so we instead produce
  #  a "flattened" list of rules
  my @rule_list;
  foreach my $rule_letter (sort { (length $b <=> length $a) || ($a cmp $b) } keys %{$rules_json}) {
    foreach my $line (@{$rules_json->{$rule_letter}}) {
      # parse a rule
      # split at equals and brackets into a prev, current, next, and output
      if ($line =~ m/$line_regex/) {
        # convert prev and next into regex portions
        my ($prev, $current, $next, $result) = ($1, $2, $3, $4);

        $prev =~ s/$class_regex/$classes{$1}/g;
        $prev = qr/${prev}$/;

        $next =~ s/$class_regex/$classes{$1}/g;
        $next = qr/^\Q$current\E${next}/;

        # stash pre- and post- context, token length, and the result
        push @rule_list, [$prev, $next, length($current), $result];
      } else {
        warn "Failed to parse rule: '$line'";
      }
    }
  }
  @rule_list;
};

if (DEBUG) {
  # rules dump and phoneme report
  print STDERR "RULES REPORT\n------------\n";
  my %phonemes = ();
  foreach my $rule (@rules) {
    print STDERR $rule->[0] . ' [' . $rule->[2] . '] ' . $rule->[1] . ' = ' . $rule->[3] . "\n";
    my $temp_rule = $rule->[3];
    $temp_rule =~ s/[\[\]\/]//g;
    foreach my $phon (split / /, $temp_rule) {
      $phonemes{$phon} ++
    }
  }
  print STDERR "\nPHONEME FREQ\n------------\n";
  foreach my $phon (sort keys %phonemes)
  {
    print STDERR "$phon: $phonemes{$phon}\n"
  }
}

# Main processing

# read input file
my $input = do { local $/; <STDIN> };

# Time to clean up the input
$input = ' ' . uc($input) . ' ';
# Add spaces around each non-letter
$input =~ s/([^A-Z ]+)/ $1 /g;
# Standardize other whitespacing
$input =~ s/\s+/ /g;

# print normalized string
if (DEBUG) { print STDERR "Normalized input: [$input]\n" }

# now convert
my $idx = 1;
while ($idx < length($input)) {
  # redoing substrings like this is probably NOT the fastest solution...
  my $parsed = substr $input, 0, $idx;
  my $rest = substr $input, $idx;

  # attempt rule matching
  if (my $rule = first { $parsed =~ m/$_->[0]/ && $rest =~ m/$_->[1]/ } @rules)
  {
      if (DEBUG) { print STDERR "Matched rule $rule->[0] [$rule->[2]] $rule->[1]\n" }
      # matched!  output pronunciation
      print $rule->[3];
      # advance by the token length
      $idx += $rule->[2];
      next;
  } else {
    # No match to any known rules - this is a bad character or something.
    warn "RULE ERROR: Failed to match at position $idx in '$input'\n\tfrom here: " . substr($rest, 10) . '...';
    print " ";
    $idx ++;
  }
}

# all done!
