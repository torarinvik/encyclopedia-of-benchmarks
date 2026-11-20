# Rights and provenance

The RosettaGit [Forest fire task](https://rosettagit.org/tasks/forest-fire/) was used to discover the algorithm and identify a three-state cellular-automaton variant. Drossel and Schwabl's 1992 paper, [“Self-organized critical forest-fire model,” *Physical Review Letters* 69 (1992)](https://doi.org/10.1103/PhysRevLett.69.1629), and their later [general stochastic forest-fire model](https://arxiv.org/abs/cond-mat/9310059) were consulted for the model's mathematical state transitions and stochastic growth/lightning mechanisms.

This package expresses the rules and an explicitly bounded benchmark contract in original prose and code. It preserves the selected task variant's permanently empty outermost row and column, Moore-neighbor ignition, synchronous updates, and probabilistic growth/lightning decisions. It does not copy or adapt implementation source code, task wording, fixtures, tests, or published outputs. The supplied draw tapes and thresholds are benchmark-defined deterministic replay inputs. No RosettaGit implementation is bundled.

The references and ten language ports are original implementations from the stated transition rules. The workload vectors are small hand-derived cases. This note records provenance; it does not claim ownership or grant rights to the cited publications or task page.
