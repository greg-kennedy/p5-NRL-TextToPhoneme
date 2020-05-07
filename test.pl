#!/usr/bin/env perl
use strict;

use Test::More;

# Series of tests produced from the NRL paper
my @tests = (
  {
    in => 'RATIO',
    out => '/R//EY//SH//OW//< >/',
  },
  {
    in => 'THE TIME HAS COME, THE WALRUS SAID, TO TALK OF MANY THINGS--OF SHOES, AND SHIPS, AND SEALING WAX, OF CABBAGES AND KINGS,',
    out => '/DH AX//< >//T//AY//M// //< >//HH//AE//Z//< >//K AH M// //< >//<,>//< >//DH AX//< >//W//AO L//R//AH//S//< >//S EH D//< >//<,>//< >//T UW//< >//T//AO K//< >//AX V//< >//M//EH N IY//< >//TH//IH//NX//Z//< >//<->//<->//< >//AX V//< >//SH//OW// //Z//< >//<,>//< >//AE//N//D//< >//SH//IH//P//S//< >//<,>//< >//AE//N//D//< >//S//IY//L//IH//NX//< >//W//AE//K S//< >//<,>//< >//AX V//< >//K//AE//B//B//IH JH//IH Z//< >//AE//N//D//< >//K//IH//NX//Z//< >//<,>//< >/',
  },
  {
    in => 'AND WHY THE SEA IS BOILING HOT, AND WHETHER PIGS HAVE WINGS.',
    out => '/AE//N//D//< >//WH//AY//< >//DH AX//< >//S//IY//< >//IH//Z//< >//B//OY//L//IH//NX//< >//HH//AA//T//< >//<,>//< >//AE//N//D//< >//WH//EH//DH ER//< >//P//IH//G//Z//< >//HH AE V// //< >//W//IH//NX//Z//< >//<.>//< >/',
  },
  {
    in => 'SUICIDE',
    out => '/S//UW//IH//S//AY//D// //< >/',
  },
);

plan tests => scalar @tests;

foreach my $test(@tests) {
  my $cmd = 'echo "' . $test->{in} . '" | ./NRL-TTP.pl';
  my $output = `$cmd`;
  is($output, $test->{out}, $test->{in});
}
