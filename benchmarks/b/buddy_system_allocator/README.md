# Buddy system allocator

This benchmark replays a bounded allocation/free trace over a fixed arena. It
measures the buddy-system policy: requests round up to power-of-two blocks,
larger free blocks split recursively, and a released block merges recursively
with an available equal-sized buddy.

## Contract

Input is a signed-i64 vector `[operation_count, (opcode, id, argument)*]`.
There are at most 64 operations in a 256-unit arena. Opcode `0` allocates the
requested size `argument` (1 through 256) for an ID in 0 through 31. IDs must
be unique while live and can be reused after a successful free. Opcode `1`
frees a live ID and requires `argument == 0`. An allocation that cannot be
satisfied is a valid operation and leaves its ID unused; it emits status `0`,
base `-1`, and size `0`. A successful allocation emits status `1`, the
zero-based block base, and the rounded block size. A successful free emits
status `1` and the released block's original base and rounded size.

The arena begins as one free block `[0,256)`. The requested size rounds up to
the smallest power of two that can contain it. The allocator searches from
that order upward, choosing the lowest base among free blocks at the first
available order. A selected larger block is split repeatedly; the lower
half stays under allocation and each upper half becomes free. On release, the
allocator merges with a free buddy while possible. For a block of size `s`,
its buddy base is `base XOR s`.

The output is little-endian signed-i64 words: three words per operation
`[status, base, rounded_size]`, followed by a final free-block count and
`(base, size)` pairs sorted by base. The final list exposes coalescing state.
The maximum valid input is 193 words; the parser accepts one additional word
to diagnose a trailing-data frame, for a 194-word parse bound. The conservative
output bound is 5,640 bytes and workspace is capped at 16,384 bytes. Malformed
framing, invalid IDs or
operation fields, duplicate live IDs, and freeing an inactive ID return `-1`
without output. After complete input validation and simulation, a null or
short output buffer returns `-2` without writes. Otherwise the function
returns the output byte count. Even an empty operation trace emits the initial
free block.

## References

- NIST DADS, [“buddy system”](https://xlinux.nist.gov/dads/HTML/buddysystem.html), an algorithm discovery and terminology entry.
- S. M. Donahue, M. P. Hampton, R. K. Cytron, M. Franklin, and K. Kavi, [“Hardware Support for Fast and Bounded-Time Storage Allocation”](https://engineering.unt.edu/cse/research/labs/csrl/files/wmpi02.pdf), §3.1, summarizing request rounding, upward free-list search, recursive splitting, and buddy coalescing.

The primary reference uses order-indexed free lists. The independent reference
stores a sorted list of maximal dyadic free intervals and scans it by size
class. Both references are clean-room and use different state representations.

## Workload and package files

- Workload: [`workload.json`](workload.json)
- Primary oracle: [`primary_oracle.py`](primary_oracle.py)
- Independent oracle: [`independent_oracle.py`](independent_oracle.py)
- Workload/oracle verifier: [`verify_workload.py`](verify_workload.py)
- Static inventory checker: [`check_inventory.py`](check_inventory.py)
- Rights and provenance: [`RIGHTS.md`](RIGHTS.md)

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/buddy_system_allocator.c`](../../../c/b/buddy_system_allocator.c) |
| C3 | [`c3/b/buddy_system_allocator.c3`](../../../c3/b/buddy_system_allocator.c3) |
| C++ | [`cpp/b/buddy_system_allocator.cpp`](../../../cpp/b/buddy_system_allocator.cpp) |
| Elisa | [`elisa/b/buddy_system_allocator.elisa`](../../../elisa/b/buddy_system_allocator.elisa) |
| Mojo | [`mojo/b/buddy_system_allocator.mojo`](../../../mojo/b/buddy_system_allocator.mojo) |
| Nim | [`nim/b/buddy_system_allocator.nim`](../../../nim/b/buddy_system_allocator.nim) |
| Odin | [`odin/b/buddy_system_allocator.odin`](../../../odin/b/buddy_system_allocator.odin) |
| Rust | [`rust/b/buddy_system_allocator.rs`](../../../rust/b/buddy_system_allocator.rs) |
| V | [`v/b/buddy_system_allocator.v`](../../../v/b/buddy_system_allocator.v) |
| Zig | [`zig/b/buddy_system_allocator.zig`](../../../zig/b/buddy_system_allocator.zig) |

The package is registered with the shared `i64_array_bytes_output` runner and
verifier and listed in the repository catalog. No programs, tests, scripts,
checkers, builds, compilers, profilers, or benchmarks were run.
