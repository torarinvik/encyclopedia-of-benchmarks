# Unordered rooted-tree enumeration

Enumerate every nonisomorphic unordered rooted-tree shape with `n` vertices.
Input is exactly `[n]`, where `1 <= n <= 7`. Children of a vertex form a
multiset, so permutations of the same child shapes are one tree. Each tree is
serialized recursively as `(`, its child encodings sorted lexicographically,
and `)`. Output begins with a little-endian u16 count, followed by the
lexicographically sorted fixed-width encodings. For a valid call with no output
buffer or insufficient capacity, return `-2` without writing; malformed input
returns `-1`.

The generator builds each size from nondecreasing multisets of already
generated smaller trees whose sizes sum to `n - 1`. This produces each
unordered shape once. The bounded primary oracle uses this recurrence; the
independent oracle enumerates labeled trees from Prüfer sequences, roots each
at vertex zero, canonicalizes its children, and deduplicates the resulting
shapes. The maximum is 48 encodings of 14 bytes plus the two-byte count.

This profile is distinct from [`parentheses_generator`](../parentheses_generator/README.md),
which enumerates ordered (plane) rooted trees, and from
[`rooted_tree_isomorphism_classification`](../rooted_tree_isomorphism_classification/README.md),
which classifies a supplied batch instead of generating every shape. The
[Rosetta Code task](https://rosettagit.org/tasks/list-rooted-trees/) was used
to identify the enumeration problem. Implementations, contracts, and fixtures
are clean-room; its text, examples, tests, and community code are not reused.
The count sequence is cross-referenced with [OEIS A000081](https://oeis.org/A000081).

| Language | Port |
|---|---|
| C | [c/r/list_rooted_trees.c](../../../c/r/list_rooted_trees.c) |
| C3 | [c3/r/list_rooted_trees.c3](../../../c3/r/list_rooted_trees.c3) |
| C++ | [cpp/r/list_rooted_trees.cpp](../../../cpp/r/list_rooted_trees.cpp) |
| Elisa | [elisa/r/list_rooted_trees.elisa](../../../elisa/r/list_rooted_trees.elisa) |
| Mojo | [mojo/r/list_rooted_trees.mojo](../../../mojo/r/list_rooted_trees.mojo) |
| Nim | [nim/r/list_rooted_trees.nim](../../../nim/r/list_rooted_trees.nim) |
| Odin | [odin/r/list_rooted_trees.odin](../../../odin/r/list_rooted_trees.odin) |
| Rust | [rust/r/list_rooted_trees.rs](../../../rust/r/list_rooted_trees.rs) |
| V | [v/r/list_rooted_trees.v](../../../v/r/list_rooted_trees.v) |
| Zig | [zig/r/list_rooted_trees.zig](../../../zig/r/list_rooted_trees.zig) |
