# Tower of Hanoi

This benchmark recursively generates the canonical sequence that moves a stack of disks from a source peg to a destination peg using one auxiliary peg.

## Contract

- Input is a signed 64-bit array: [disk_count, source_peg, destination_peg, auxiliary_peg].
- Disk counts range from 0 through 12. Peg IDs are 0, 1, and 2 and must be distinct.
- The recursive order is: move the upper n-1 disks from source to auxiliary, move one disk from source to destination, then move n-1 disks from auxiliary to destination.
- On success, the function returns the move count and writes each move as two bytes: source peg followed by destination peg. The move count is 2^n - 1.
- Invalid input returns -1. Insufficient output capacity returns -2 without writing output.
- The maximum workload uses 12 disks, producing 4,095 moves and 8,190 output bytes. Implementations use portable recursion and caller-provided output storage.

The pinned C and Python implementations recursively emit moves. The C++ source simulates the same recurrence while updating tower state. The Rust and Julia sources also produce the same sequence for positive disk counts; Julia does not terminate for zero disks, so its mapped domain excludes that case. The shared contract records the move sequence instead of printing it so all nine language ports can be checked identically.

## Workload and verification

workload.json covers zero through twelve disks, peg permutations, invalid parameters, and the maximum output size. The verifier checks every disk count with all six peg permutations, validates every move against the legal tower state, and checks that all disks finish on the destination peg.

Build with the i64_array_bytes_output ABI family. benchmarks/run_i64_array_bytes_output.py records measurements, and benchmarks/verify_tower_of_hanoi.py verifies all nine language ports.

## Additional pinned sources

- [Rust `hanoi.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/hanoi.rs)
- [Julia `hanoi.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/basic/hanoi.jl)
