// See ANTLR4 : https://github.com/antlr/antlr4
// This kind of works, but there's no gdscript target for ANTLR.

grammar LaecIsYou;

// First rule MUST start with a lowercase letter
// https://stackoverflow.com/questions/17078752/antlr-error99-grammar-has-no-rules
sentence
    : Subject Space Operation (Space AndOperator Space Operation)*
;

Subject
    : (ThingPrefix Space)? Things (Space ThingFilters)?
;

ThingPrefix
    : ThingPrefixWord
    | NotOperator Space ThingPrefix
;

Things
    : Thing (Space AndOperator Space Thing)*
;

ThingFilters
    : ThingFilter (Space AndOperator Space ThingFilter)*
;


ThingFilter
    : ThingFilterWord Space Things
    | NotOperator Space ThingFilter
;

ThingsOrQualities
    : ThingOrQuality (Space AndOperator Space ThingOrQuality)*
;

ThingOrQuality
    : Thing
    | Quality
;

Thing
    : ThingName
    | NotOperator Space Thing
;

Quality
    : QualityWord
    | NotOperator Space Quality
;

Operation
    : IsOperation
    | OtherOperation
;

IsOperation
    : IsOperator Space ThingsOrQualities
;

OtherOperation
    : OtherOperator Space Things
;

ThingPrefixWord
    : 'LONELY'
;

ThingWord
    : 'BABA'
    | 'TEXT'
    | '...'
;

ThingName
    : ThingWord
    | 'GROUP'
;

ThingFilterWord
    : 'ON'
    | 'NEAR'
    | 'FACING'
;

QualityWord
    : 'YOU'
    | 'SWAP'
    | 'WIN'
    | 'GROUP'
    | '...'
;

IsOperator
    : 'IS'
;

AndOperator
    : 'AND'
;

NotOperator
    : 'NOT'
;

OtherOperator
    : 'HAS'
    | 'MAKE'
    | 'EAT'
    | 'FEAR'
    | 'FOLLOW'
;

Space
    : ' ' (' ')*
;
