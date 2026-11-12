# Rights and provenance

- Algorithm description reviewed: [Rosetta Code: Kahan summation](https://rosettagit.org/tasks/kahan-summation/). The RosettaGit mirror identifies the task page content as licensed under the GNU Free Documentation License, version 1.3 or any later version. This package does not copy that page's code or prose.
- Algorithm reference: William Kahan, “Further remarks on reducing truncation errors,” *Communications of the ACM*, vol. 8, no. 1, 1965, [doi:10.1145/363707.363723](https://doi.org/10.1145/363707.363723).
- All ten language ports are clean-room implementations of the high-level compensated-summation recurrence. The Python primary and verifier oracles are independently written; the verifier models each rounded arithmetic step with exact rational values.
- No upstream source file is incorporated. No third-party source-code license is asserted for these new ports.
