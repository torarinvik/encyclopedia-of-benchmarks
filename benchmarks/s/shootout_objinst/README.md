# Shootout Objinst benchmark

The pinned source constructs heap objects and dispatches through callbacks stored on their base Toggle object. It creates a true Toggle, makes five `activate` → `value` calls, and prints `false`, `true`, `false`, `true`, `false`. It then constructs and destroys `n` additional Toggles, prints a blank line, creates a true NthToggle with `count_max = 3`, makes eight callback calls, and prints `true`, `true`, `false`, `false`, `false`, `true`, `true`, `true`. Finally it constructs and destroys `n` additional NthToggles. The NthToggle embeds Toggle first, inherits its value callback, and overrides the base activation callback.

The launcher defaults to 70,000,000 additional constructions of each type (7,000,000 with `SMALL_PROBLEM_SIZE`) and supplies no runtime options. The suite bounds `n` to [-100,000, 100,000]. Negative values retain the C loop behavior and skip both construction loops. Ports preserve the per-instance callback dispatch and perform both object-construction/destruction loops. Successful output is always the exact 72-byte stdout string below; invalid counts return -1, while null or short output buffers return -2 without writes.

```text
false
true
false
true
false

true
true
false
false
false
true
true
true
```

The `i64_scalar_bytes_output` ABI exposes `shootout_objinst(n, output, output_capacity)`. Input uses `shootout_objinst_n`; output uses `shootout_objinst_stdout_ascii`. [`workload.json`](workload.json) covers negative, zero, one, and maximum constructor counts, source framing, profile bounds, and buffer errors. [`shootout_objinst_oracle.py`](../../shootout_objinst_oracle.py) independently simulates both callback-driven state machines.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_objinst.c](../../../c/s/shootout_objinst.c) |
| C3 | [c3/s/shootout_objinst.c3](../../../c3/s/shootout_objinst.c3) |
| C++ | [cpp/s/shootout_objinst.cpp](../../../cpp/s/shootout_objinst.cpp) |
| Elisa | [elisa/s/shootout_objinst.elisa](../../../elisa/s/shootout_objinst.elisa) |
| Nim | [nim/s/shootout_objinst.nim](../../../nim/s/shootout_objinst.nim) |
| Odin | [odin/s/shootout_objinst.odin](../../../odin/s/shootout_objinst.odin) |
| Rust | [rust/s/shootout_objinst.rs](../../../rust/s/shootout_objinst.rs) |
| V | [v/s/shootout_objinst.v](../../../v/s/shootout_objinst.v) |
| Zig | [zig/s/shootout_objinst.zig](../../../zig/s/shootout_objinst.zig) |

## Pinned source

- [objinst.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/objinst.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/info.sh)
