# Rights and provenance

The algorithm was derived from the update rule in Peter K. Pearson, “Fast
Hashing of Variable-Length Text Strings,” *Communications of the ACM* 33(6),
677–680 (1990), [DOI 10.1145/78973.78978](https://doi.org/10.1145/78973.78978),
and its [NIST DADS entry](https://xlinux.nist.gov/dads/HTML/pearsonshash.html).
These sources provide algorithm attribution and behavior. They are not a
license grant for source reuse.

The brief DADS definition says the function uses no exclusive-or operation,
but the linked 1990 primary paper explicitly uses exclusive-or to index the
table. This profile follows the paper's update rule; the DADS sentence is
recorded as a conflicting summary, not as an additional algorithm branch.

No published code, article text, sample table, test fixture, or comment is
copied. The benchmark uses its own explicitly defined nibble-reversal
permutation for workload calls. The ten ports and the two references were
written independently from the mathematical update rule. No licensing status
for any external implementation was used or inferred.
