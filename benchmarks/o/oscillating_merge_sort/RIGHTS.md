# Rights and provenance

The algorithm name and high-level behavior are attributed to the public
[NIST DADS oscillating merge sort entry](https://xlinux.nist.gov/dads/HTML/oscillatingMergeSort.html),
which cites Sheldon Sobel's 1962 paper, [“Oscillating Sort—A New Sort Merging
Technique”](https://doi.org/10.1145/321127.321133). The bounded sort-call profile
fixes four tapes and a 16-value initial run size while preserving the
alternating-direction, backward-read merge structure.

The workload, primary and independent references, documentation, custom
verifier, and ten language ports were written clean-room. No implementation
code, statement text, tests, or examples were copied.
