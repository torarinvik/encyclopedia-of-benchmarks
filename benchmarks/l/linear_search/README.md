# Linear search

## Contract

Given a read-only sequence of signed 64-bit integers and a signed 64-bit target, scan from the first element to the last. Return the zero-based index of the first matching element, or `-1` when no element matches. The sequence is never modified. An empty sequence returns `-1`. Input length must fit in a signed 64-bit index.

Each implementation exposes the same C ABI entry point so one timing runner can call every language implementation:

```c
int64_t linear_search(const int64_t *values, size_t length, int64_t target);
```

The pointer refers to `length` read-only signed 64-bit integers. The runner supplies a non-null pointer for an empty sequence. The returned index fits in `int64_t` for all declared workloads.

## Workload

The machine-readable workload is in [`workload.json`](workload.json). Use lengths `0`, `16`, `1,024`, `65,536`, and `1,048,576`. Generate each nonempty input with the same formula, using signed 64-bit arithmetic and zero-based `i`:

```text
values[i] = ((i * 48,271) mod 2,000,003) - 1,000,001
```

For these lengths, all generated values are unique. For every nonempty length, run four separate search cases:

| Case | Target | Expected result |
| --- | --- | --- |
| first hit | `values[0]` | `0` |
| middle hit | `values[length / 2]` | `length / 2` |
| last hit | `values[length - 1]` | `length - 1` |
| miss | `1,000,002` | `-1` |

For length `0`, run only the miss case, with expected result `-1`. Use the same generated input for each case at a given length. Generate inputs and validate the result outside the timed section. Keep each case's target and expected result fixed during its timed repetitions.

The executable workload is described in [`workload.json`](workload.json). The shared search runner is [`benchmarks/harness/runner.c`](../../harness/runner.c), compiled with `-DBENCHMARK_FUNCTION=linear_search`; [`benchmarks/run.py`](../../run.py) appends one JSONL record per implementation and workload case using [`benchmarks/results.schema.json`](../../results.schema.json). Each record includes workload, source, runner, and binary hashes, compiler/build provenance, machine details, correctness result, timer details, and raw nanosecond samples.

The workload deliberately avoids duplicates. Implementations must still return the first matching index if a caller supplies duplicates; for example, `[7, -3, 7, 7]` searched for `7` returns `0`.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/l/linear_search.c`](../../../c/l/linear_search.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/l/linear_search.c3`](../../../c3/l/linear_search.c3) | Local port |
| C++ | [`cpp/l/linear_search.cpp`](../../../cpp/l/linear_search.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/l/linear_search.elisa`](../../../elisa/l/linear_search.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/l/linear_search.nim`](../../../nim/l/linear_search.nim) | Independent portable implementation; TheAlgorithms Nim reference below |
| Odin | [`odin/l/linear_search.odin`](../../../odin/l/linear_search.odin) | Local port |
| Rust | [`rust/l/linear_search.rs`](../../../rust/l/linear_search.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/l/linear_search.v`](../../../v/l/linear_search.v) | Local port |
| Zig | [`zig/l/linear_search.zig`](../../../zig/l/linear_search.zig) | Independent portable implementation; TheAlgorithms Zig reference below |

No architecture-specific instructions or compiler flags are required. The C and C++ sources are ready to link with the shared runner. The other ports use the same declared C ABI and can be linked once their compiler-specific object build is configured. The C11 runner uses `clock()` process CPU time and checks each result before and after timed batches.

## TheAlgorithms references

The source paths below were checked at the pinned commits listed in the catalog. The local code follows this benchmark contract and was written independently rather than copied from the upstream implementation.

- [C `linear_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/linear_search.c) — repository license reported as GPL-3.0.
- [C++ `linear_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/linear_search.cpp) — repository license reported as MIT.
- [Nim `linear_search.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/searches/linear_search.nim) — repository license reported as MIT.
- [Rust `linear_search.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/linear_search.rs) — repository license reported as MIT.
- [Zig `linearSearch.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/linearSearch.zig) — repository license reported as MIT.
