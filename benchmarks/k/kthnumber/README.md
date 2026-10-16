# K-th number

The pinned Go source exposes both `FindKthMin` and `FindKthMax`, sharing an in-place partition-based quickselect. The benchmark selects either one-based order statistic while preserving duplicate values.

## Contract

Input is `[n,mode,k,x0,...]`, where mode 1 selects the k-th smallest and mode 2 the k-th largest. There are 1..16 values in [-10000,10000], and k is in 1..n. Invalid inputs return -1.

See [workload](workload.json), [oracle](../../kthnumber_oracle.py), and pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/kthnumber.go).

| Language | Port |
|---|---|
| C | c/k/kthnumber.c |
| C3 | c3/k/kthnumber.c3 |
| C++ | cpp/k/kthnumber.cpp |
| Elisa | elisa/k/kthnumber.elisa |
| Nim | nim/k/kthnumber.nim |
| Odin | odin/k/kthnumber.odin |
| Rust | rust/k/kthnumber.rs |
| V | v/kthnumber.v |
| Zig | zig/kthnumber.zig |
