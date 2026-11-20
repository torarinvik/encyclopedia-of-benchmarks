# Weak-heapsort

Sort an input sequence in ascending order using a weak heap, then return an
order-sensitive checksum of the sorted values. Input is `[N,value_0,...]`,
with `0<=N<=256` and values in `-1000..1000`. The checksum is
`sum((i+1)*(sorted[i]+1001))`; malformed input returns `-1`.

The algorithm stores one reverse bit per heap node. It first builds a max
weak heap by joining each node with its distinguished ancestor. Each extraction
moves the root maximum to the end of the active prefix, descends the left spine
of the root's right subtree, then joins the root back up that path to restore
the weak-heap order. The primary implementation uses this reverse-bit and
distinguished-ancestor method. The independent reference sorts with the
language's standard library.

The algorithm uses `O(N log N)` time. Its heap structure uses `O(N)` reverse
bits; the read-only array ABI requires an additional `O(N)` local copy of
values. This is a distinct heap invariant and repair procedure from ordinary
binary [`heap_sort`](../../h/heap_sort/README.md).

The method is described in [NIST's weak-heapsort entry](https://xlinux.nist.gov/dads/HTML/weakheapsort.html)
and Dutton's [Weak-Heap Sort](https://doi.org/10.1007/BF01990520). Only the
algorithm descriptions were consulted; no source code, prose, or examples
were copied.

| Language | Port |
|---|---|
| C | [c/w/weak_heapsort.c](../../../c/w/weak_heapsort.c) |
| C3 | [c3/w/weak_heapsort.c3](../../../c3/w/weak_heapsort.c3) |
| C++ | [cpp/w/weak_heapsort.cpp](../../../cpp/w/weak_heapsort.cpp) |
| Elisa | [elisa/w/weak_heapsort.elisa](../../../elisa/w/weak_heapsort.elisa) |
| Mojo | [mojo/w/weak_heapsort.mojo](../../../mojo/w/weak_heapsort.mojo) |
| Nim | [nim/w/weak_heapsort.nim](../../../nim/w/weak_heapsort.nim) |
| Odin | [odin/w/weak_heapsort.odin](../../../odin/w/weak_heapsort.odin) |
| Rust | [rust/w/weak_heapsort.rs](../../../rust/w/weak_heapsort.rs) |
| V | [v/w/weak_heapsort.v](../../../v/w/weak_heapsort.v) |
| Zig | [zig/w/weak_heapsort.zig](../../../zig/w/weak_heapsort.zig) |
