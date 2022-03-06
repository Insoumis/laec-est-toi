## EBNF-like description of the grammar

Unused configuration for ANTLR.  (not `LL(1)`, but perhaps could be?)

This would be a clean way of describing the DSL (Domain Specific Language)
of a puzzle game such as *Baba Is You*.

Sadly, making ANTLR generate a Godot-ready parser and lexer is more work
than I'm willing to accomplish for this project.

If you want to take this on, go for it !

---

Right now we're going to have to make do with a hardcoded, rigged parser.

(see `core/Sentence.gd`)
