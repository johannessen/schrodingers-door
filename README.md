# Schrödinger’s Door

## A tribute to Tau Station

The \*ahem\* “mission system” implemented here is really just the bare
minimum for the Schrödinger’s Door mission; the simplest thing I could
get away with. It supports some branching, enough for this quite linear
mission. But should you try to write your own mission on top of this
code, you’ll probably run into its limits very soon. Caveat emptor.

Storing the mission in a YAML file wasn’t a great choice. I mean,
obviously, a format easily editable by humans is needed, so it’s still
better than JSON or XML. I thought I could save time by using a format
that’s already established, so I could skip writing a parser. But the
intricacies of YAML meant I ended up spending a considerable amount of
time making sure the indentation was correct and stuff. If this software
is expanded, it would probably be useful to consider switching to
something like Markdown as a primary format, which is much better suited
to writing swaths of text. However, that might mean that the choices and
their effects might have to be stored separately.

### License

Schrödinger’s Door created 2023 by
[Arne Johannessen](https://arne.johannessen.de)

The text of this mission itself is available under the terms of
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/),
and the underlying source code used to format and display the
mission is available under the
[ISC license](https://github.com/johannessen/schrodingers-door/blob/main/LICENSE).

This is a private project and not an official offer by the creators of
[Tau Station](https://allaroundtheworld.fr/game), formerly available
at [taustation.space](https://taustation.space).
