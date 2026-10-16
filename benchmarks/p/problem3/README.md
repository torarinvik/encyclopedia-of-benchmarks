# Project Euler Problem 3

## Contract

Return the largest prime factor of `number`, for inputs in `2..=600,851,475,143`. Inputs outside that range return `-1`.

The ports use trial division, repeatedly removing a discovered factor and stopping once the current factor is greater than the square root of the remaining value. They run in O(sqrt(number)) time and use O(1) extra space. The Go source accepts a parameter; Haskell and PHP solve the fixed Project Euler input `600851475143`, which is the upper bound of this contract.

## Workload

[`workload.json`](workload.json) covers primes, repeated factors, small composite examples, the Project Euler example, the canonical input, and invalid values.

## TheAlgorithms references

- Go [`Problem3`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_3/problem3.go) repeatedly divides out the current factor until its parameter reaches one.
- Haskell [`Problem3.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem3/Problem3.hs) finds the largest factor of the fixed canonical input by trial division.
- PHP [`Problem3.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem3.php) divides out factors of the fixed canonical input while the divisor is below its square root.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem3.c](../../../c/p/problem3.c) |
| C3 | [c3/p/problem3.c3](../../../c3/p/problem3.c3) |
| C++ | [cpp/p/problem3.cpp](../../../cpp/p/problem3.cpp) |
| Elisa | [elisa/p/problem3.elisa](../../../elisa/p/problem3.elisa) |
| Nim | [nim/p/problem3.nim](../../../nim/p/problem3.nim) |
| Odin | [odin/p/problem3.odin](../../../odin/p/problem3.odin) |
| Rust | [rust/p/problem3.rs](../../../rust/p/problem3.rs) |
| V | [v/p/problem3.v](../../../v/p/problem3.v) |
| Zig | [zig/p/problem3.zig](../../../zig/p/problem3.zig) |
