# EBNF to BNF translator - mm16197

## files

- `mm16197.trans.l` - flex scanner for the translator
- `mm16197.trans.y` - bison grammar + translation code
- `mm16197.trans.sh` - builds the translator (`./trans`)
- `mm16197.tinybasic.in` - tiny basic grammar in EBNF-enhanced form
- `mm16197.tinybasic.l` - flex scanner for tiny basic
- `mm16197.tinybasic.sh` - translates the .in file into `mm16197.tinybasic.y`, then builds the tiny basic parser
- `sample.bas` - tiny basic program to test with

## running

```
sh mm16197.trans.sh
./trans < mm16197.tinybasic.in > mm16197.tinybasic.y

# or all in one, and parse sample.bas
sh mm16197.tinybasic.sh sample.bas
```

A good program prints `valid tiny basic program`. Bad input prints `syntax error ...` to stderr and exits with 1.
The translator does the same thing for bad EBNF input.

Tested with bison 3.7.4, flex 2.6.4, g++.

## how the translation works

Each piece of a rule's right side gets turned into a string of BNF symbols. When an EBNF
construct shows up, a new rule is made and its name goes into the string instead:

- `( A || B )` -> `X_grp : A | B ;` (a group with only one alternative is just put inline)
- `[ A || B ]` -> `X_opt : /* empty */ | A | B ;`
- `< A >` and `A*` -> `X_star : /* empty */ | X_star A ;`
- `A+` -> `X_plus : A | X_plus A ;`

X is the rule's name plus a counter. If the name is already used somewhere in the file
the counter goes up until it isn't. New rules are printed right after the rule that made them.

Sections 1 and 3 are copied as they are. Actions stay where they were written.
If the input uses `%union` and typed tokens, the new rules get a `%type` line when all their
alternatives start with the same type, so `$1` still works in the user's actions.

The translator grammar has no shift/reduce or reduce/reduce conflicts.

## tiny basic notes

- `=` is used by LET and is also a relop, so the scanner returns `EQUALS` for it and IF takes `( RELOP || EQUALS )`
- the handout makes the sign at the start of `expression` required, but then `LET A = 1` doesn't parse, so it is `[ PLUMIN ]`
- blank lines are skipped, and the last line doesn't need a newline
- spaces inside a number (`GOTO 10 20`) are a syntax error
