# Project Euler Problem 4

## Contract

Given a digit count in `1..=3`, return the largest palindrome made from the product of two positive integers with exactly that many decimal digits. Inputs outside that range return `-1`.

The ports scan factor pairs from largest to smallest and stop when no remaining pair can exceed the best palindrome. They test palindromes by reversing the product's decimal digits. Runtime is O(10^(2d) × d) in the worst case for `d` digits, with O(1) extra space. The Go, Haskell, and PHP sources solve the fixed three-digit instance; their exact shared-contract input is `digits == 3`.

## Workload

[`workload.json`](workload.json) covers one-, two-, and three-digit factor ranges, plus invalid digit counts.

## TheAlgorithms references

- Go [`Problem4`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_4/problem4.go) scans three-digit factor pairs and checks products using its palindrome helper.
- Haskell [`Problem4.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/ProjectEuler/Problem4/Problem4.hs) takes the maximum three-digit product whose decimal representation is palindromic.
- PHP [`Problem4.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem4.php) scans unique three-digit factor pairs and compares each product with its reversed string.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem4.c](../../../c/p/problem4.c) |
| C3 | [c3/p/problem4.c3](../../../c3/p/problem4.c3) |
| C++ | [cpp/p/problem4.cpp](../../../cpp/p/problem4.cpp) |
| Elisa | [elisa/p/problem4.elisa](../../../elisa/p/problem4.elisa) |
| Nim | [nim/p/problem4.nim](../../../nim/p/problem4.nim) |
| Odin | [odin/p/problem4.odin](../../../odin/p/problem4.odin) |
| Rust | [rust/p/problem4.rs](../../../rust/p/problem4.rs) |
| V | [v/p/problem4.v](../../../v/p/problem4.v) |
| Zig | [zig/p/problem4.zig](../../../zig/p/problem4.zig) |
