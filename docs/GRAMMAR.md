 
## EBNF (Extended Backus–Naur Form)

Somewhat valid, but not `LL(1)`.


```ebnf

Sentence
    = Subject, Space, Operation, { Space, AndOperator, Space, Operation }
;

Subject
    = [ThingPrefix, Space], Things, [Space, ThingFilters]
;

ThingPrefix
    = ThingPrefixWord
    | NotOperator, Space, ThingPrefix
;

Things
    = Thing, { Space, AndOperator, Space, Thing }
;

ThingFilters
    = ThingFilter, { Space, AndOperator, Space, ThingFilter }
;

ThingFilter
    = ThingFilterWord, Space, Things
    | NotOperator, Space, ThingFilter
;

ThingsOrQualities
    = ThingOrQuality, { Space, AndOperator, Space, ThingOrQuality }
;

ThingOrQuality
    = Thing
    | Quality
;

Thing
    = ThingName
    | NotOperator, Space, Thing
;

Quality
    = QualityWord
    | NotOperator, Space, Quality
;

Operation
    = IsOperation
    | OtherOperation
;

IsOperation
    = IsOperator, Space, ThingsOrQualities
;

OtherOperation
    = OtherOperator, Space, Things
;

ThingPrefixWord
    = "LONELY"
;

ThingWord
    = "BABA"
    | "TEXT"
    | "..."
;

ThingName
    = ThingWord
    | "GROUP"
;

ThingFilterWord
    = "ON"
    | "NEAR"
    | "FACING"
;

QualityWord
    = "YOU"
    | "SWAP"
    | "WIN"
    | "GROUP"
    | "..."
;

IsOperator
    = "IS"
;

AndOperator
    = "AND"
;

NotOperator
    = "NOT"
;

OtherOperator
    = "HAS"
    | "MAKE"
    | "EAT"
    | "FEAR"
    | "FOLLOW"
;

Space
    = " ", { " " }
;

```

Inspiration: https://gist.github.com/ashastral/6cd4d0112360a461878e731db1ee59e5

---

## Statement Structure

    SUBJECTS VERB COMPLEMENTS



### SUBJECTS

Required.
Multiple subjects are separated by `AND`.

    EPITHETS NOUN ATTRIBUTES


#### EPITHETS

Optional.
Can be negated.
Multiple epithets are separated by `AND`.

Eg: `LONELY`


#### NOUN

Required.
Can be negated.
Only one.  We use `AND` on whole subjects instead.
    
    THING | SYNTH

Eg: `BABA` _(thing)_, `EMPTY` _(synth)_


#### ATTRIBUTES

Optional.
Can be negated.
Multiple attributes are separated by `AND`.
Usually two words.

    PREPOSITION NOUN

Eg: `ON GRASS`, `FACING WALL`


### VERB

Required.
Can be negated, perhaps?
Only one verb.  (perhaps leave room to support multiple, with `AND`?)

Eg: `IS`, `HAS`


### COMPLEMENTS

Required.
Can be negated.
Multiple complements are separated by `AND`.
Depends on the verb.

    IS:  QUALITY | THING | SYNTH
    HAS: THING


