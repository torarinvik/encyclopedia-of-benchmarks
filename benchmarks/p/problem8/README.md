# Project Euler Problem 8

## Contract

Given a window length in `1..=13`, return the greatest product of that many consecutive digits in the fixed 1,000-digit Project Euler series. Inputs outside the range return `-1`.

The ports scan every legal window and multiply its digits directly, taking O(1000 × window) time and O(1) extra space. The Go source accepts a window length and PHP fixes it at 13. Both pinned loops omit the final legal starting position; the shared contract includes it. PHP also restarts a running product after it reaches zero, so zero-containing windows can differ from direct multiplication. These source quirks do not change the canonical 13-digit maximum of 23,514,624,000.

## Workload

[`workload.json`](workload.json) covers a single digit, the four-digit example, the canonical 13-digit window, and invalid lengths.

## TheAlgorithms references

- Go [`Problem8`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_8/problem8.go) scans its fixed 1,000-digit string for a caller-provided window length.
- PHP [`Problem8.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/ProjectEuler/Problem8.php) scans the same series using a fixed window length of 13.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem8.c](../../../c/p/problem8.c) |
| C3 | [c3/p/problem8.c3](../../../c3/p/problem8.c3) |
| C++ | [cpp/p/problem8.cpp](../../../cpp/p/problem8.cpp) |
| Elisa | [elisa/p/problem8.elisa](../../../elisa/p/problem8.elisa) |
| Nim | [nim/p/problem8.nim](../../../nim/p/problem8.nim) |
| Odin | [odin/p/problem8.odin](../../../odin/p/problem8.odin) |
| Rust | [rust/p/problem8.rs](../../../rust/p/problem8.rs) |
| V | [v/p/problem8.v](../../../v/p/problem8.v) |
| Zig | [zig/p/problem8.zig](../../../zig/p/problem8.zig) |
