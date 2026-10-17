# Least recently used cache

This benchmark follows the pinned Python `LRUCache` reference sequence. The cache keeps the most recently used key at the front of its deque and the least recently used key at the back. Referencing a key already in the cache moves it to the front. Referencing a new key adds it at the front, evicting the key at the back when the cache is full.

The source stores capacity on the class, and capacity zero switches to an effectively unbounded default. Each benchmark call creates a fresh cache, uses an explicit capacity from 1 through 16, and processes at most 64 references. The source's generic keys are restricted to signed 32-bit integers for this contract.

## Contract

Input is `[capacity, reference_count, key...]`. Capacity is 1–16, reference count is 0–64, and each key is a signed 32-bit integer. Each key represents one call to `refer`.

Output is a variable-length vector of little-endian signed 64-bit integers: `[size, most_recently_used_key, ..., least_recently_used_key]`. The function returns the number of output elements. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. A zero-reference trace returns `[0]`.

See [workload](workload.json), [oracle](../../least_recently_used_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/least_recently_used.py).

| Language | Port |
|---|---|
| C | [c/l/least_recently_used.c](../../../c/l/least_recently_used.c) |
| C3 | [c3/l/least_recently_used.c3](../../../c3/l/least_recently_used.c3) |
| C++ | [cpp/l/least_recently_used.cpp](../../../cpp/l/least_recently_used.cpp) |
| Elisa | [elisa/l/least_recently_used.elisa](../../../elisa/l/least_recently_used.elisa) |
| Nim | [nim/l/least_recently_used.nim](../../../nim/l/least_recently_used.nim) |
| Odin | [odin/l/least_recently_used.odin](../../../odin/l/least_recently_used.odin) |
| Rust | [rust/l/least_recently_used.rs](../../../rust/l/least_recently_used.rs) |
| V | [v/l/least_recently_used.v](../../../v/l/least_recently_used.v) |
| Zig | [zig/l/least_recently_used.zig](../../../zig/l/least_recently_used.zig) |
