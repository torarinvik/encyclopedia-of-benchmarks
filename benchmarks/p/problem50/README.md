# Project Euler Problem 50: Consecutive prime sum

## Contract

For an exclusive ceiling from 3 through 1,000,000, return the prime below the ceiling that is produced by the longest sum of consecutive primes. The ports build a prime sieve, then scan start indices in ascending order and extend each sum until it reaches the ceiling. They preserve the source's tie behavior by updating the result whenever an equally long prime sum is found later in the traversal. Invalid ceilings return `-1`.

The canonical result below one million is 997,651. The search uses O(ceiling) sieve storage and a bounded list of primes; the canonical workload is run once per sample without warmup.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_050/sol1.py) sieves primes below the exclusive ceiling and scans start indices in ascending order. For each start it tests end indices beginning at the current longest length, breaks once the sum reaches the ceiling, and updates the longest length and result when the sum is prime. It documents 499 at ceiling 500, 953 at 1,000, 9,521 at 10,000, and 997,651 below one million. The sieve appends 2 separately and iterates odd candidates, so its prime list remains correct despite not marking pure powers of two in the backing flag array.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem50.c](../../../c/p/problem50.c) |
| C3 | [c3/p/problem50.c3](../../../c3/p/problem50.c3) |
| C++ | [cpp/p/problem50.cpp](../../../cpp/p/problem50.cpp) |
| Elisa | [elisa/p/problem50.elisa](../../../elisa/p/problem50.elisa) |
| Nim | [nim/p/problem50.nim](../../../nim/p/problem50.nim) |
| Odin | [odin/p/problem50.odin](../../../odin/p/problem50.odin) |
| Rust | [rust/p/problem50.rs](../../../rust/p/problem50.rs) |
| V | [v/p/problem50.v](../../../v/p/problem50.v) |
| Zig | [zig/p/problem50.zig](../../../zig/p/problem50.zig) |
