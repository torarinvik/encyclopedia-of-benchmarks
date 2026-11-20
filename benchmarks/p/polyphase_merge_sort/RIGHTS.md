# Rights and provenance

The profile follows the method described by the NIST Dictionary of Algorithms
and Data Structures entry for [polyphase merge sort](https://xlinux.nist.gov/dads/HTML/polyphmrgsrt.html)
and the corresponding [polyphase merge](https://xlinux.nist.gov/dads/HTML/polyphmerge.html)
entry. For the bounded three-tape specialization and its Fibonacci run
distribution, the source is R. L. Shores, *System/360 Sorting Techniques*,
IBM Technical Information Exchange Z77-7257 (3 October 1967), pp. 18 and 43
([digitized report](https://ftpmirror.your.org/pub/misc/bitsavers/pdf/ibm/technical_information_exchange/Z77-7257_Shores_-_System_360_Sorting_Techniques_19671003.pdf)).

The ports use the algorithm description only. No implementation code or
source prose was copied. The in-memory tape model and the fixed run size are
benchmark contract choices.
