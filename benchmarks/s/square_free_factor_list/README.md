# Square-free factor list

## Contract

Return `1` when every signed 32-bit integer in the input list is unique, and `0` when any value is repeated. Lists of length 0 through 256 are supported; other lengths, a null pointer with nonzero length, or values outside int32 return `-1`. Validate every element before deciding uniqueness, so an invalid value takes precedence over an earlier duplicate. Empty input returns `1`, including with a null pointer. The exported C ABI entry point is `int64_t square_free_factor_list(const int64_t *values, size_t length);`.

## Source review

The pinned Python `is_square_free(factors)` function returns whether `len(set(factors)) == len(factors)`. It does not factor a number or validate that the entries are prime; it only checks uniqueness. This benchmark preserves that list operation over bounded integer inputs. The ports use pairwise comparisons within the small fixed input limit, while the Python source uses a set.

[`contains_duplicate`](../../c/contains_duplicate/README.md) computes the complementary predicate, but its ports sort a copy with heapsort before scanning. This profile's pairwise scan takes O(n²) time and O(1) auxiliary space; the sort-and-scan profile takes O(n log n) time and O(n) space. The distinct computational behavior warrants retaining both workloads.

## Workload

[`workload.json`](workload.json) covers empty and unique lists, repeated values, negative and zero factors, and the int32 value boundary.

An independent set-based [oracle draft](../../square_free_factor_list_oracle.py) validates the full input before checking uniqueness. The shared i64-array scalar runner and verifier now include draft oracle wiring and boundary cases. This integration, the oracle, and the ports have not been executed.

Static review added missing nonempty-null guards to the Elisa, V, and Zig ports;
the Elisa port uses a bounded view after checking its ABI input. These changes
have not been compiled or run.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/square_free_factor_list.c`](../../../c/s/square_free_factor_list.c) |
| C3 | [`c3/s/square_free_factor_list.c3`](../../../c3/s/square_free_factor_list.c3) |
| C++ | [`cpp/s/square_free_factor_list.cpp`](../../../cpp/s/square_free_factor_list.cpp) |
| Elisa | [`elisa/s/square_free_factor_list.elisa`](../../../elisa/s/square_free_factor_list.elisa) |
| Nim | [`nim/s/square_free_factor_list.nim`](../../../nim/s/square_free_factor_list.nim) |
| Odin | [`odin/s/square_free_factor_list.odin`](../../../odin/s/square_free_factor_list.odin) |
| Rust | [`rust/s/square_free_factor_list.rs`](../../../rust/s/square_free_factor_list.rs) |
| V | [`v/s/square_free_factor_list.v`](../../../v/s/square_free_factor_list.v) |
| Zig | [`zig/s/square_free_factor_list.zig`](../../../zig/s/square_free_factor_list.zig) |
| Mojo | [`mojo/s/square_free_factor_list.mojo`](../../../mojo/s/square_free_factor_list.mojo) |

## TheAlgorithms reference

- [Python `is_square_free.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/is_square_free.py)
