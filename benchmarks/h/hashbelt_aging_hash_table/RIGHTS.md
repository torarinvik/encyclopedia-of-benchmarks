# Rights and provenance

The algorithm idea and terminology were discovered through NIST's Dictionary
of Algorithms and Data Structures entry for [hashbelt](https://xlinux.nist.gov/dads/HTML/hashbelt.html).
The entry cites William Grosso, “The Hashbelt Data Structure,” O'Reilly
ONJava.com, January 2002. The benchmark pins a small deterministic profile of
the entry's table-generation rotation and older-hit promotion note. Promotion
removes the entry from its previous generation so each key has one live copy.

The package uses no copied source code, comments, protected article prose, or
published example traces. All language ports, workload cases, and reference
implementations are written independently. The primary and independent
references use different in-memory representations. The community or index
entry is provenance and algorithm description only, not a source of code or
fixtures. No rights claim is made over the cited algorithm.
