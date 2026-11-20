# Rights and provenance

The algorithm is based on Michael T. Goodrich and Michael Mitzenmacher,
“Invertible Bloom Lookup Tables,” *Proceedings of the 49th Annual Allerton
Conference on Communication, Control, and Computing* (2011), arXiv version 3
(2015), [arXiv:1101.2245](https://arxiv.org/abs/1101.2245), especially the
cell update and listing sections and the checksum extension. The NIST DADS
[invertible Bloom lookup table entry](https://xlinux.nist.gov/dads/HTML/invertibleBloomTable.html)
is used for discovery and terminology.

Only algorithmic behavior is used. No source code, pseudocode wording,
examples, figures, or fixtures are copied or adapted. The fixed placement
family, key-only workload, checksum polynomial, tie order, output framing,
references, and ten language ports are independently authored. This
deterministic bounded profile makes no random-hash success guarantee.
