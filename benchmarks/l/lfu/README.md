# LFU cache

This benchmark exposes bounded traces against the pinned Go `LFU` cache. It
preserves the behavior of that source, including two quirks in its frequency
helper and existing-key update path.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[capacity, operation_count, records...]`. Capacity is 2 through 16,
  and the trace contains 0 through 32 operations. The packed input has at most
  98 signed-i64 words.
- Opcode `0` is `Put(key, value)` and consumes three words total. Opcode `1` is
  `Get(key)` and consumes two words total. Records must exactly fill the input.
  Keys and values are signed 32-bit integers. A key is converted to its
  canonical base-10 string for the source's `map[string]` key.
- New entries start at frequency 1. The pinned `increaseFreq` helper removes
  and reinserts a copied item without incrementing its frequency. A successful
  get and a duplicate put move the item to the front of the frequency-1 list;
  the duplicate put's attempted value update is lost because the helper reads
  the original list element. Consequently, eviction among accepted entries is
  least-recently-used, and duplicate puts preserve the old value.
- Capacity below 2 is excluded. Capacity 0 panics on insertion. At capacity 1,
  accessing the sole frequency-1 item can advance `minFreq` while reinserting
  it at frequency 1, so a later full-cache insertion can panic.
- Each put emits `[0]`. A get emits `[1, 0, value]` when present or `[1, 1, 0]`
  when absent. Words are serialized as little-endian signed 64-bit integers.
  The result is bytes written; malformed input returns `-1`, and a null output
  pointer or insufficient capacity returns `-2` without writing.
- The maximum output is 768 bytes: 32 get operations each emit three words.

The independent oracle is [`lfu_oracle.py`](../../lfu_oracle.py). The workload
covers touches and eviction order, the lost duplicate-put update, empty and
missing reads, capacity limits, malformed traces, and output capacity edges.

## Pinned sources

- [Go `lfu.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cache/lfu.go), which defines `NewLFU`, `Get`, `Put`, frequency movement, and eviction.
- [Go `lru.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cache/lru.go), which defines the shared `item` structure used by `lfu.go`.

## Implementations

| Language | Port |
| --- | --- |
| C | [c/l/lfu.c](../../../c/l/lfu.c) |
| C3 | [c3/l/lfu.c3](../../../c3/l/lfu.c3) |
| C++ | [cpp/l/lfu.cpp](../../../cpp/l/lfu.cpp) |
| Elisa | [elisa/l/lfu.elisa](../../../elisa/l/lfu.elisa) |
| Nim | [nim/l/lfu.nim](../../../nim/l/lfu.nim) |
| Odin | [odin/l/lfu.odin](../../../odin/l/lfu.odin) |
| Rust | [rust/l/lfu.rs](../../../rust/l/lfu.rs) |
| V | [v/l/lfu.v](../../../v/l/lfu.v) |
| Zig | [zig/l/lfu.zig](../../../zig/l/lfu.zig) |
