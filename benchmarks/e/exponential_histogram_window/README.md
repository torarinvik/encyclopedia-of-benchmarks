# Exponential histogram for a bit-stream window (draft)

This reserved profile maintains a bounded exponential histogram of the most
recent `window` bits. It follows the bucket-counting idea in [Datar, Gionis,
Indyk, and Motwani](https://www.cs.princeton.edu/courses/archive/spr04/cos598B/bib/DatarGIM.pdf).
The existing [`adwin`](../../a/adwin/README.md) also groups observations into
exponential buckets, but maintains real-valued sums and variances and changes
the window by testing for distribution drift. This profile instead expires
buckets against a fixed window and estimates the number of one-bits.

The proposed `i64_array_bytes_output` input is `[window,n,bits[n]]`, with
`1<=window<=64`, `0<=n<=128`, and each bit either 0 or 1. The array length
must equal `2+n`. After each bit, expire every bucket whose newest timestamp is
outside the last `window` positions; add a size-one bucket for a one-bit; then
while more than two buckets have the same size, merge the two oldest, retaining
the newer of their timestamps. Resolve overflowing sizes from smallest upward.
For each prefix, output twice the estimated count: twice the sum of all bucket
sizes minus the oldest bucket's size, or zero for an empty histogram. This
integer representation avoids a floating-point rounding convention.

Output is `n` little-endian signed i64 words in prefix order. Invalid or null
input returns -1. A null output or capacity below `8*n` returns -2 after input
validation, including for an empty output; errors do not write output. Maximum
valid/parseable input lengths are 130/131 words; maximum output is 1024 bytes.
With at most 128 observed bits, this draft uses fixed bounded bucket storage.
The intended general representation uses `O(log window)` buckets; the draft
reference scans the bucket list at each size level and takes
`O(n log²(window+1))` time.

The implementation contract and references are original. No code, examples,
or prose are copied from the paper. Two independently structured references
and [C](../../../c/e/exponential_histogram_window.c), [C3](../../../c3/e/exponential_histogram_window.c3), [C++](../../../cpp/e/exponential_histogram_window.cpp),
[Elisa](../../../elisa/e/exponential_histogram_window.elisa), [Nim](../../../nim/e/exponential_histogram_window.nim),
[Odin](../../../odin/e/exponential_histogram_window.odin), [Rust](../../../rust/e/exponential_histogram_window.rs),
[V](../../../v/e/exponential_histogram_window.v), [Mojo](../../../mojo/e/exponential_histogram_window.mojo),
and [Zig](../../../zig/e/exponential_histogram_window.zig) drafts are present.
Workload fixtures, an inventory checker, and byte-output suite wiring are drafted. No
draft has been executed.
