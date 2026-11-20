# Rights and provenance

The RosettaGit task “Generate Chess960 starting position” was used as a task
discovery source and for the standard placement constraints:
https://rosettagit.org/tasks/generate-chess960-starting-position/.

The index mapping is attributed to Reinhard Scharnagl and cross-checked with
the Scharnagl/van Reem Chess960 rules and numbering tables:
https://de.chessbase.com/portals/3/files/2006/scharnagl/chess960_regeln.pdf.
The opposite-color bishops and king-between-rooks rules were also checked
against FIDE's Chess960 appendix:
https://www.fide.com/docs/regulations/ARB%20Manual%202020.pdf.

This package defines a deterministic ID-unranking benchmark inspired by the
task's position-generation scope. It does not implement random sampling. No
task wording, implementation, published output example, or test was copied.
The mixed-radix ports, reverse-ranking reference, workload, and fixture
outputs are original to this bounded profile.
