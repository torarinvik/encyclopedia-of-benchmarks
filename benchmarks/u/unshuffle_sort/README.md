# UnShuffle sort

UnShuffle sort distributes values, in input order, into ordered doubly-ended
queues called piles. A value is added to the front of the first pile whose
front is at least that value, or to the back of the first pile whose back is
at most that value. If neither endpoint can accept it, a new pile is created.
The piles are then combined by an ideal merge: a min-heap holds each pile's
current front, emits the least one, and advances that pile.

This is a bounded signed-64-bit `sort_call` benchmark for arrays of length zero
through 1,024. The C ABI receives an auxiliary array allocated by the harness
outside timed regions. Language ports use a fixed-capacity node-link table to
represent the deques, pile endpoints, and merge heap; the values stay in the
input until the final heap merge writes the sorted output to scratch. Equal
keys may be emitted from any pile because the contract requires sorted values,
not stability.

If `K` piles are formed, a direct scan for the first fitting pile costs
`O(nK)` in the worst case and the heap merge costs `O(n log K)`. Inputs already
in nondecreasing or nonincreasing order form one pile and take linear work.
The case suite includes ordered, reverse-ordered, duplicate-heavy, separated
and interleaved values, and signed 64-bit boundaries. The primary reference
simulates the endpoint-pile distribution and heap merge; the independent
reference uses built-in integer ordering.

UnShuffle sort differs from [`strand_sort`](../../s/strand_sort/README.md), which
repeatedly extracts one increasing subsequence and merges it into an accumulated
result. UnShuffle forms several endpoint-extendable ordered deques in one
distribution pass, then performs a heap-based ideal merge of all their heads.
It also differs from [`linear_probing_sort`](../../l/linear_probing_sort/README.md),
which distributes values into a key-indexed open-addressed table.

The custom sort verifier is
[`benchmarks/verify_unshuffle_sort.py`](../../verify_unshuffle_sort.py); the
package workload and inventory check is `verify_workload.py`. Neither has been
run.

Sources: [NIST DADS UnShuffle sort](https://xlinux.nist.gov/dads/HTML/unshufflsort.html)
and Art S. Kagel, “Unshuffle Algorithm, Not Quite a Sort?”, *Computer Language*,
3(11), November 1985. Algorithm descriptions only; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

See [`INVENTORY.md`](INVENTORY.md) for the ten-language source map.
