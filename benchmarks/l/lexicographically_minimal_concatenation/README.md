# Lexicographically minimal string concatenation

Given a collection of nonempty lowercase ASCII strings, arrange and join them
to obtain the lexicographically smallest result. The comparator orders `a`
before `b` when the virtual string `a+b` is lexicographically smaller than
`b+a`. Equal virtual strings may occur; any order of such strings gives the
same concatenated output. This differs from [`string_heap_sort`](../../s/string_heap_sort/README.md),
which sorts fixed-width keys directly, and from
[`largest_of_very_large_numbers`](../../l/largest_of_very_large_numbers/README.md),
which compares numerical powers.

The proposed `i64_array_bytes_output` input is `[count, (length, bytes...)...]`.
There are 0 to 16384 strings, each nonempty and made of ASCII bytes 97 to 122,
with at most 65536 bytes in total. The frame must have no trailing elements.
Return the raw concatenated bytes and their count; malformed input returns -1,
and a null or undersized output returns -2 without writes, including for empty
output. Maximum valid input length is 81921 i64 values.

The draft builds a suffix array over all strings separated by sentinel bytes,
then uses longest-common-prefix range minima to compare the virtual strings in
constant time per comparison without materializing them. A doubling suffix
sort gives O(L log² L) preprocessing, O(L log L) LCP-table space, and
O(N log N + L) ordering/output time, where L includes separators. The
independent reference enumerates string orders for small instances.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1414)
is used as an idea index; its repository declares Apache-2.0. The bounded
contract, implementation, reference and prose are independently authored,
without copied task text, examples or code.

Reserved and in progress: ten language drafts, independent references,
fixtures, a workload validator and byte-suite registration are present.
Static review separated the Nim suffix-class buffer from the original text.
The verifier specifies long shared prefixes and maximum-sized word and count
frames. Nothing has been compiled or run.
