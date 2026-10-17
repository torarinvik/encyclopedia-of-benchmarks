# Quadratic probing

This benchmark measures the pinned Python `QuadraticProbing.insert_data`
behavior over a short, deterministic sequence of integer keys. Every call
starts with a fresh table.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[capacity, insert_count, key_0, ..., key_(insert_count-1)]`.
  Capacity is 5 through 31, insert count is 0 through 3, and each key is a
  nonnegative signed 64-bit integer. The input length must equal
  `2 + insert_count`.
- Each key uses Python's nonnegative remainder `key % capacity` as its home
  slot. If the home slot is empty, the key is placed there; if that slot
  already contains the same key, the source skips the insertion.
- On a collision, the source probes
  `(home + i*i) % capacity` for `i = 1, 2, ...`, starting at `i = 1`.
  The table is kept below the base class's default 0.75 load threshold, and
  the three-insertion limit ensures the accepted traces terminate without
  growth. Initial state is reset for every call.
- The pinned source's collision method receives the home-slot index as its
  `key` argument. Its occupied-slot test compares stored values with that
  home index rather than with the inserted key. This can overwrite a displaced
  value; the benchmark preserves that behavior. Repeated keys whose home slot
  is already occupied by a different value can also be inserted more than
  once, matching the source.
- Output is a little-endian signed 64-bit sequence `[capacity, slot_0, ...]`.
  Empty slots are `-1`; stored keys are emitted unchanged, including zero.
  The byte count is always `8 * (capacity + 1)`, at most 256 bytes.
- Malformed input returns `-1` before output checks. For valid input, a null
  output pointer or capacity below the output byte count returns `-2`, with no
  writes. Exact capacity succeeds.

The workload includes home-slot insertion, the first and second quadratic
offsets, wraparound, duplicate behavior, zero-valued keys, and the source's
home-index comparison edge case. Each fixture starts from a new empty table.

## Pinned sources

- [`quadratic_probing.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/quadratic_probing.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class `QuadraticProbing` and `_collision_resolution`.
- Its inherited table behavior comes from [`hash_table.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/hashing/hash_table.py) at the same commit (`HashTable.__init__`, `hash_function`, `balanced_factor`, and `insert_data`).

The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/quadratic_probing_oracle.py`](../../quadratic_probing_oracle.py).
