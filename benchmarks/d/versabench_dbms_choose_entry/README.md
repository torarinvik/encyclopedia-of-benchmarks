# VersaBench DIS R-tree child selection

This package isolates the `chooseEntry` operation in the pinned DIS Data Management benchmark. During R-tree insertion, it selects the existing child entry that incurs the smallest increase in 4D hyperrectangle volume when unioned with the incoming entry. Equal penalties retain the earliest child, matching the source's strict comparison.

## Contract

The `i64_array_scalar` input is `[child_count, child bounds..., incoming bounds]`. Each box is encoded as its four lower coordinates `(T,X,Y,Z)`, then its four upper coordinates. `child_count` is 1 through 8, coordinates are integers in `[-8,8]`, and every lower coordinate must be strictly less than its corresponding upper coordinate. The exact length is `1 + 8*child_count + 8`; one extra value is accepted by the parser only to reject trailing input. Invalid framing, bounds, or boxes return `-1`.

For each child, compute `volume(union(child,incoming)) - volume(child)`, where volume is the product of the four side lengths. Return the zero-based child index with the smallest penalty. The source stores these values as `Float`; this bounded profile uses exact integer arithmetic because all coordinates and resulting volumes are small integers exactly representable in binary32. Strictly smaller penalties replace the current choice, so ties keep the first entry.

This is the bounded R-tree branch-choice helper, not the complete database benchmark. The source's insert/split/query/delete routines, dataset parser, output formatting, and metrics harness are outside the profile.

## Source attribution and rights

The operation is `chooseEntry` in [`VersaBench/dbms/chooseEntry.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/chooseEntry.c), supported by `penalty.c`, `keyUnion.c`, `volume.c`, and `indexKey.h`, pinned at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher `VersaBench/dbms/info.sh` compiles the DIS database application against its reference command stream. The source headers identify M. L. Rivas and carry `Copyright 1999, Atlantic Aerospace Electronics Corp.`; no explicit redistribution license was present in the pinned directory. This package is an independent implementation of the documented mathematical operation and copies no upstream source code or comments. The absence of an upstream license grant is recorded here rather than treated as a license.

The independent oracle is [`versabench_dbms_choose_entry_oracle.py`](../../versabench_dbms_choose_entry_oracle.py); fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/d/versabench_dbms_choose_entry.c`](../../../c/d/versabench_dbms_choose_entry.c)
- C3: [`c3/d/versabench_dbms_choose_entry.c3`](../../../c3/d/versabench_dbms_choose_entry.c3)
- C++: [`cpp/d/versabench_dbms_choose_entry.cpp`](../../../cpp/d/versabench_dbms_choose_entry.cpp)
- Elisa: [`elisa/d/versabench_dbms_choose_entry.elisa`](../../../elisa/d/versabench_dbms_choose_entry.elisa)
- Nim: [`nim/d/versabench_dbms_choose_entry.nim`](../../../nim/d/versabench_dbms_choose_entry.nim)
- Odin: [`odin/d/versabench_dbms_choose_entry.odin`](../../../odin/d/versabench_dbms_choose_entry.odin)
- Rust: [`rust/d/versabench_dbms_choose_entry.rs`](../../../rust/d/versabench_dbms_choose_entry.rs)
- V: [`v/d/versabench_dbms_choose_entry.v`](../../../v/d/versabench_dbms_choose_entry.v)
- Zig: [`zig/d/versabench_dbms_choose_entry.zig`](../../../zig/d/versabench_dbms_choose_entry.zig)

No runtime, compiler, or validator verification is claimed.
