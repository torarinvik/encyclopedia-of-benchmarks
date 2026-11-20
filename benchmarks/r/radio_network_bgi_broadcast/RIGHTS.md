# Rights and provenance

Algorithm attribution: Reuven Bar-Yehuda, Oded Goldreich, and Alon Itai,
“Randomized Broadcasting in Radio Networks,” *Encyclopedia of Algorithms*,
Chapter 322, [DOI 10.1007/978-1-4939-2864-4_322](https://doi.org/10.1007/978-1-4939-2864-4_322),
especially §§1 and 2.1.1–2.1.3. The chapter is available from the
[Technion author page](https://csaws.cs.technion.ac.il/~itai/publications/Distributed/Radio/EOA_radio-2007_08_01.pdf).
The underlying protocol appears in Bar-Yehuda, Goldreich, and Itai,
“On the Time-Complexity of Broadcast in Multi-Hop Radio Networks: An
Exponential Gap Between Determinism and Randomization,” *Journal of Computer
and System Sciences* 45(1), 104–126 (1992), [DOI
10.1016/0022-0000(92)90042-H](https://doi.org/10.1016/0022-0000(92)90042-H),
§§2.1–2.2. In §2.2, the original paper defines `k=2*ceil(log2(Delta))` and
`t=ceil(log2(N/epsilon))`. This package fixes `N=n` and `epsilon=1/2`.
The Chapter 322 PDF transcription appears to add an extra leading factor of
two before `ceil` in the displayed `t` expression; this profile follows the
original paper's §2.2 formula.

The bounded implementation interprets the source's one-off initialization
message as the source's first Decay send at slot 0. A newly informed processor
waits for the next global slot divisible by `k`; the receipt slot itself is
never also a transmission slot. Coins are supplied as data and replayed
deterministically. Each receiver accepts only an exactly-one-neighbor send;
the implementation does not model collision detection or capture effects.
Goldreich's [author errata page](https://www.wisdom.weizmann.ac.il/~oded/p_bgi.html)
notes that the paper's deterministic lower-bound argument was initially stated
for a stronger collision model than the proof supports. This benchmark makes
no lower-bound or probabilistic-success claim.

The source works are used for attribution and algorithm behavior only. All
ports, references, and fixtures are independently written for this
repository. No source code, chapter prose, published example trace, or
third-party workload data is included; no license over the cited works is
asserted.
