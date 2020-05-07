# p5-NRL-TextToPhoneme
Perl implementation of the Naval Research Laboratory text-to-phoneme algorithm,
described by Elovitz _et al._ (1976).

## Usage
    echo "HELLO WORLD" | ./NRL-TTP.pl
    /HH//EH//L// //OW//< >//W ER//L//D//< >/

## Introduction
Early speech synthesizers worked by concatenating together distinct "phonemes"
(speech sounds), either recordings sampled from human speech or synthesized in
software. This approach can generate passable human speech from very limited
resources. For instance, the General Instruments SP0256-AL2 can synthesize 59
different sounds from a 2 kilobyte ROM and a tiny sequencer to drive the output
generation. An external controller provides the sequence of phonemes for the
synthesizer to produce (e.g. the word "RATIO" is converted to "R EY SH OW").

Pronunciation of words for speech synthesis generally uses one of two main
strategies: a large dictionary for direct translation of words to phonemes, or
a rule-based system that attempts to determine phonemes from the spelling of a
word. Because early speech synthesizers lacked the storage space to hold such
a dictionary, designers needed a rule system to convert text into speech - but
not so difficult that it could not run on the processors of the day.

One of the earliest common rule-based algorithms for English text-to-phoneme
was written in 1976, in a collaboration between the Naval Research Laboratory
and Votrax International, Inc. (then Federal Screw Works). It was first printed
in an NRL report:

> Elovitz, H., Johnson, R., McHugh, A., & Shore, J. (January 21, 1976). _Automatic Translation of English Text to Phonetics by Means of Letter-to-Sound Rules_. _NRL Report, Issue 5418, Part 7948_.

and later re-published in an IEEE journal:

> Elovitz, H., Johnson, R., McHugh, A., & Shore, J. (1976). _Letter-to-sound rules for automatic translation of english text to phonetics_. _IEEE Transactions on Acoustics, Speech, and Signal Processing, 24(6), 446–459_. doi:10.1109/tassp.1976.1162873

(There was a correction in a followup IEEE journal, but it did not alter the
rules or algorithm. Incidentally, the IEEE version DOES have a misprint: the
rule ` [OU]^L=/AH/` should have been instead `^[OU]^L=/AH/`)

The NRL report is more comprehensive than the IEEE version. In particular, it
includes translation rules from IPA to Votrax synthesizer, as well as the
complete Snobol source for the TRANS and DICT programs.

This is a Perl implementation of the algorithm, written to parse and use the
original rule set published in the paper.

## How It Works
Because the features of speech synthesizers differ, the authors rejected the
idea of translating directly from text to synthesizer code. Instead, the
program takes a two-pass approach to preparing text for speaking. The first
pass is to convert input text from freeform ASCII input to a subset of IPA
pronunciation. A second pass then translates the IPA output into code for a
particular synthesizer.

This table (reproduced from the paper) shows the IPA symbols output, as well as
the corresponding letter codes from the output. The ASCII letter codes are also
called [ARPABET](https://en.wikipedia.org/wiki/ARPABET), though slightly
different here. ARPABET was common in many speech synthesizers for early 8-bit
computer systems.

| Standard IPA | Representation | Example
| --- | --- | ---
| i | IY | b*ee*t
| ɪ | IH | b*i*t
| e | EY | g*a*te
| ɛ | EH | g*e*t
| æ | AE | f*a*t
| a | AA | f*a*ther
| ɔ | AO | l*aw*n
| o | OW | l*o*ne
| ʊ | UH | f*u*ll
| u | UW | f*oo*l
| ɝ, ɚ | ER | m*ur*d*er*
| ə | AX | *a*bout
| ʌ | AH | b*u*t
| aɪ | AY | h*i*de
| aʊ | AW | h*ow*
| ɔɪ | OY | t*oy*
| p | P | *p*ack
| b | B | *b*ack
| t | T | *t*ime
| d | D | *d*ime
| k | K | *c*oat
| ɡ | G | *g*oat
| f | F | *f*ault
| v | V | *v*ault
| θ | TH | e*th*er
| ð | DH | ei*th*er
| s | S | *s*ue
| z | Z | *z*oo
| ʃ | SH | lea*sh*
| ʒ | ZH | lei*s*ure
| h | HH | *h*ow
| m | M | su*m*
| n | N | su*n*
| ŋ | NX | su*ng*
| l | L | *l*augh
| w | W | *w*ear
| j | Y | *y*oung
| r | R | *r*ate
| tʃ | CH | *ch*ar
| dʒ | JH | *j*ar
| hw | WH | *wh*ere

The program accepts as input an ASCII string to parse. Input should be
"normalized" by uppercasing all characters, adding spaces before and after each
group of non-letter characters, and then condensing consecutive white-space
characters to one. For example, the input string

    Hello there, I am a TI 960A computer.  What's your name?

will become

    HELLO THERE , I AM A TI 960 A COMPUTER . WHAT ' S YOUR NAME ?

Translation from normalized text to phoneme is done by looping over the input
string, attempting matches to a set of ordered rules, and outputting the result
of each match. The rule definitions look like this:

    [A] =/AX/
     [ARE] =/AA R/
     [AR]O =/AX R/
    [AR]#=/EH R/
     ^[AS]#=/EY S/
    [A]WA=/AX/
     :[ANY]=/EH N IY/
    [A]^+#=/EY/
    #:[ALLY]=/AX L IY/
     [AL]#=/AX L/
    [AGAIN]=/AX G EH N/
    #:[AG]E=/IH JH/
    [A]^+:#=/AE/
     :[A]^+ =/EY/

Rules have (up to) four parts:
* Optional Preceding context that must match
* Exact character sequence that must match (in [SQUARE BRACKETS])
* Optional Following context that must match
* Phoneme group to output (after =EQUALS SIGN)

Some pre- and post-context contain characters with a special meaning:

| Symbol | Meaning
| --- | ---
| # | One or more vowels<sup>†</sup>
| . | One of B, D, V, G, J, L, M, N, R, W, Z: a voiced consonant
| % | One of ER, E, ES, ED, ING, ELY: a suffix
| & | One of S, C, G, Z, X, J, CH, SH: a sibilant
| @ | One of T, S, R, D, L, Z, N, J, TH, CH, SH: a consonant influencing the sound of following *U* (cf. *rule*, *mule*)
| ^ | One consonant<sup>‡</sup>
| + | One of E, I, Y: a front vowel
| : | Zero or more consonants

<sup>†</sup>Vowels are A, E, I, O, U, Y.
<sup>‡</sup>Consonants are B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Z

To parse a line and apply rules:
* Check the letter(s) beginning from the current cursor position to bracketed
  groups in the rule set.
* If a match is found, check the pre- and post-context around the bracketed
  letters for a match. (The beginning and end of string have an implicit space
  character appended)
* If that matches, copy the result pronunciation to output buffer. Advance
  the cursor beyond the bracketed group and continue.
* All letters should (eventually) match, as the last line in each letter rule
  group is a "default" rule (e.g. `[Z]=/Z/`)
  * Digits also have hard-coded rules (e.g. `[1]=/W AH N/`)
  * Punctuation characters have rules too, and are printed using the special
    pattern `/<X>/`, where X is the character matched. These can be used to
    indicate spaces, punctuation or other pauses to the synthesizer.
* Unknown characters print a warning and are treated as a space (silence).

## PERL IMPLEMENTATION
The original version of this algorithm was coded in Snobol, and relied heavily
on character string manipulation features of that language. By contrast, this
Perl version uses modern constructs, like regular expressions, to perform the
rule application.

One annoying "feature" of the Snobol program is that, though it does translate
from ASCII to synthesizer through an intermediate IPA step, the output files
are not actually formatted to make this translation easy. There is a special
case flag that changes parsing from "sentence based" to "blocks surrounded by
//". This makes it difficult to use Unix pipe to make translations and also is
somewhat incompatible with standard ARPABET, which separates syllables with a
space, and words with a slash.

This version supports only the initial English-to-IPA translation.  A later
release will likely add support for the second IPA-to-Votrax (or other synth)
step.

Rules are kept in a folder called `rules/` and written as a JSON file. The
group names are arbitrary and reproduced from the original paper. Note that
rules from one group must NOT interfere with those from another: for instance
an "ER" group and an "E" group will probably not work properly, because the
final rule for "E" could prevent a match against "ER", depending on sort order
of the Perl hash.  (The 1976 IPA-to-Votrax rules actually do this, so there is
a workaround in the script, but you shouldn't rely on it.)

Three sets of rules are provided:
* `eng_to_ipa.json` - the original ruleset for English to IPA, reproduced from
  the NRL paper tables and code.
* `ipa_to_votrax.json` - the original ruleset for IPA to Votrax (SC-01 or other
  standalone synthesizer), reproduced from the NRL paper. This is for a second
  pass to convert IPA phonemes into input for the Votrax, and includes a number
  of "liquid l" rules as recommended by the manufacturer.
* `ipa_to_sp0256.json` - an example ruleset for IPA to General Instruments
  SP0256-AL2. This are my own work :)

By default the script accepts input from `STDIN` and prints translations to
`STDOUT`. You may choose ruleset by giving a path to the rules file as the
first command-line argument. If not specified, it defaults to
`rules/eng_to_ipa.json`.

There is a constant DEBUG option at the top of the script. When enabled, it
prints some diagnostic output to `STDERR`. This may be useful for rules testing
or other development.
