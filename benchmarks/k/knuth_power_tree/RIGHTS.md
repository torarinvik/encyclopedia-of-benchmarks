# Rights and provenance

This package was identified through Rosetta Code's
[Knuth's power tree task](https://rosettacode.org/wiki/Knuth%27s_power_tree)
and its [RosettaGit mirror](https://rosettagit.org/tasks/knuths-power-tree/).
Rosetta Code task content is described by its copyrights notice as GNU Free
Documentation License 1.2; this package does not reproduce task prose,
examples, submitted code, or page output. See the
[Rosetta Code copyrights page](https://rosettagit.org/drafts/rosetta-code-copyrights/).

The implementation is a clean-room bounded reconstruction of the shared
first-discovery power tree described in Donald E. Knuth, *The Art of Computer
Programming*, Vol. 2, §4.6.3. It stores each previously unseen exponent once,
and records the path from 1 to the requested exponent. It does not copy or
adapt submitted source code.
