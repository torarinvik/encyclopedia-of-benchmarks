# LCFS hashing

This profile implements NIST DADS last-come-first-served hashing with linear
probing. A new key claims its home slot. If occupied, it takes that slot and
displaces the resident; the resident continues to the next slot, taking it
and displacing its occupant until the first empty slot is reached. Each
resident displacement is counted once. This differs from ordinary linear
probing, which lets the newcomer continue past residents, and Robin Hood
hashing, which swaps according to relative probe distance.

The scalar ABI receives `[capacity, n, keys...]`, with capacity in `1..=32`,
`0 <= n <= capacity`, unique keys in `[0, 1_000_000]`, and exact length `n+2`.
The result is the number of resident displacements; malformed input returns
`-1`. The table occupies 256 bytes at the maximum capacity. The bounded
workload includes collisions, resident chains, wraparound, a full table, and
invalid frames and keys.

The algorithm description is from the [NIST Dictionary of Algorithms and Data
Structures LCFS hashing entry](https://xlinux.nist.gov/dads/HTML/lcfsHashing.html).
The local ports implement the described rule without copying source code.

Ten ports are present in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
