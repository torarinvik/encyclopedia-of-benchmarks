# Monotone radix heap

This draft processes a sequence of integer insertions and minimum removals.
Keys must be at least the most recently removed key. A radix heap groups keys
by the bit length of their XOR with that last minimum. When bucket zero is
empty, it finds the minimum key in the first nonempty bucket, advances the
minimum, and redistributes that bucket according to the new XOR prefixes.
[`dial_bucket_shortest_paths`](../../d/dial_bucket_shortest_paths/README.md)
instead uses exact-distance circular buckets, while general heap packages use
comparison ordering.

The scalar input is `[Q,(opcode,key)*Q]`, with `0<=Q<=64`. Opcode `0`
inserts a key in `0..2147483647` that is at least the last removed key
(initially zero). Opcode `1` removes one minimum and requires its key field to
be zero. Removing from an empty heap, invalid operations, null input, or a
wrong-length frame returns `-1`. Duplicate keys are allowed. Return the sum of
removed keys weighted by their one-based removal index; no removals returns
zero. Exact valid/parseable input lengths are at most 129/130 i64 words.

There are 32 buckets for 31-bit keys and at most 64 stored insertion records.
For this fixed-word implementation each record is redistributed at most 31
times; scanning each 31-bit XOR for its highest bit gives a conservative
`O(Q*W²)` time bound and `O(Q+W)` space for `W=31`. The mathematical radix-heap
idea is described by [Ahuja et al.](https://doi.org/10.1145/77600.77615);
only the idea is used, without copying code or prose. Two reference drafts and
ten language drafts, the workload, rights note, package checker, and scalar
runner/verifier registration are independently authored. The verifier source
specifies short operation traces, boundary keys, maximum frames, and null
inputs. The workload also covers reinsertion at the last removed key and keys
straddling bit 30. The Elisa draft uses a bounded input view and indexed fixed arrays.
Nothing has been compiled or run.
