# Polybius cipher

The pinned Go `Polybius` constructor accepts a key, square size, and coordinate alphabet. Encryption uppercases the input and maps each key character to its row and column symbols.

## Contract

This benchmark fixes size 5, key `ABCDEFGHIKLMNOPQRSTUVWXYZ`, and coordinate alphabet `ABCDE`. The key omits J, so I and J are merged by excluding J from valid inputs. Input is `[byte_count, ASCII letters...]`, with up to 64 letters. Lowercase is accepted and uppercased. Output contains two coordinate letters for each input letter; invalid input returns `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../polybius_oracle.py). Pinned source: [TheAlgorithms/Go `polybius.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/polybius/polybius.go).

| Language | Port |
|---|---|
| C | [`c/p/polybius.c`](../../../c/p/polybius.c) |
| C3 | [`c3/p/polybius.c3`](../../../c3/p/polybius.c3) |
| C++ | [`cpp/p/polybius.cpp`](../../../cpp/p/polybius.cpp) |
| Elisa | [`elisa/p/polybius.elisa`](../../../elisa/p/polybius.elisa) |
| Nim | [`nim/p/polybius.nim`](../../../nim/p/polybius.nim) |
| Odin | [`odin/p/polybius.odin`](../../../odin/p/polybius.odin) |
| Rust | [`rust/p/polybius.rs`](../../../rust/p/polybius.rs) |
| V | [`v/p/polybius.v`](../../../v/p/polybius.v) |
| Zig | [`zig/p/polybius.zig`](../../../zig/p/polybius.zig) |
