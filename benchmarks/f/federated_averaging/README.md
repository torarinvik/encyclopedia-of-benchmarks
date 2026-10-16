# Federated averaging

This benchmark follows the pinned Python `federated_average` operation on one scalar tensor per client. It uses the source's explicit nonnegative client-weight path: weights are normalized by their positive sum, then used to aggregate corresponding client values. The source's shape validation reduces here to requiring one value per client.

Input is `[client_count, weights..., client_values...]`, with 1–8 clients, integer weights in 0–1000, and integer scalar values in -1000–1000. Weights must sum to a positive value. The ABI returns the weighted average as binary64. Invalid inputs return `-1e300`. This bounded scalar-tensor contract excludes NumPy array shape handling and the optional equal-weight convenience path.

The runtime oracle is [`federated_averaging_oracle.py`](../../federated_averaging_oracle.py); workload cases are in [`workload.json`](workload.json).

Pinned source: [TheAlgorithms/Python `federated_averaging.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/federated_averaging.py).

| Language | Port |
|---|---|
| C | [`c/f/federated_averaging.c`](../../../c/f/federated_averaging.c) |
| C3 | [`c3/f/federated_averaging.c3`](../../../c3/f/federated_averaging.c3) |
| C++ | [`cpp/f/federated_averaging.cpp`](../../../cpp/f/federated_averaging.cpp) |
| Elisa | [`elisa/f/federated_averaging.elisa`](../../../elisa/f/federated_averaging.elisa) |
| Nim | [`nim/f/federated_averaging.nim`](../../../nim/f/federated_averaging.nim) |
| Odin | [`odin/f/federated_averaging.odin`](../../../odin/f/federated_averaging.odin) |
| Rust | [`rust/f/federated_averaging.rs`](../../../rust/f/federated_averaging.rs) |
| V | [`v/f/federated_averaging.v`](../../../v/f/federated_averaging.v) |
| Zig | [`zig/f/federated_averaging.zig`](../../../zig/f/federated_averaging.zig) |
