# Rights and provenance

This package contains clean-room references and ports of the bounded
next-fixed-popcount operation. The RosettaCodeData “Gospers-hack” title was
used only for discovery and duplicate mapping; its task text, examples, tests,
submissions, and source code were not used.

The algorithm idea is attributed to HAKMEM Item 175 in MIT AI Memo 239:

- https://dspace.mit.edu/bitstream/handle/1721.1/6086/AIM-239.pdf

The pinned C++ and Java implementations are corroborating examples of the
same operation and edge behavior:

- https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/next_higher_number_with_same_number_of_set_bits.cpp
- https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NextHigherSameBitCount.java

The title index used for discovery is pinned at:

- https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks

No implementation code or task prose was copied. The primary reference uses
the lowest-set-bit formula; the independent reference manipulates the binary
string. All source and reference files in this package were written for this
repository.
