# ANSIbench Dhrystone 2.1 bounded core profile

This package translates the deterministic per-pass core of ANSIbench's Dhrystone 2.1 source into a fixed small workload. The input is one integer pass count in `[1, 8]`. Each pass runs the source-ordered procedure/function sequence, including record assignment and mutation, fixed string copies and comparison, the two-dimensional array updates, control flow, and integer arithmetic. The initial records, strings, and `Arr_2_Glob[8][7]` value follow the pinned source.

The output is 19 one-byte state fields: final integer and boolean globals, character globals, the updated array entries, selected variant fields and pointer indices for both records, the final pass locals, and a flag showing the `Func_2` false result. Errors return `-1` for invalid input and `-2` for a null or undersized output; output is staged before it is copied.

This profile excludes the timing and reporting wrapper and fixes the pass count to a small range. It is a deterministic Dhrystone-derived workload, **not an official Dhrystone score** and must not be presented as one.

## Source and attribution

Pinned source: [`nfinit/ansibench` Dhrystone 2.1 core at commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/dhrystone). The source credits Reinhold P. Weicker (1988); the repository's Dhrystone license note states that the original benchmark and its ANSI C modifications are public domain. See [the upstream notice](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/dhrystone/LICENSE) and the included [LICENSE](LICENSE).

The implementations here are independent translations of the documented core operations. They do not include the original timing/reporting harness.

## Workload, oracle, and ports

- Workload: [`workload.json`](workload.json)
- Oracle: [`ansibench_dhrystone_oracle.py`](../../ansibench_dhrystone_oracle.py)

The nine implementations are [C](../../../c/a/ansibench_dhrystone.c), [C3](../../../c3/a/ansibench_dhrystone.c3), [C++](../../../cpp/a/ansibench_dhrystone.cpp), [Elisa](../../../elisa/a/ansibench_dhrystone.elisa), [Nim](../../../nim/a/ansibench_dhrystone.nim), [Odin](../../../odin/a/ansibench_dhrystone.odin), [Rust](../../../rust/a/ansibench_dhrystone.rs), [V](../../../v/a/ansibench_dhrystone.v), and [Zig](../../../zig/a/ansibench_dhrystone.zig).
