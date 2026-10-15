# Square-free factor list

## Contract

Return `1` when every signed 32-bit integer in the input list is unique, and `0` when any value is repeated. Lists of length 0 through 256 are supported; other lengths or values outside int32 return `-1`. Empty input returns `1`. The exported C ABI entry point is `int64_t square_free_factor_list(const int64_t *values, size_t length);`.

## Source review

The pinned Python `is_square_free(factors)` function returns whether `len(set(factors)) == len(factors)`. It does not factor a number or validate that the entries are prime; it only checks uniqueness. This benchmark preserves that list operation over bounded integer inputs. The ports use pairwise comparisons within the small fixed input limit, while the Python source uses a set.

## Workload

[`workload.json`](workload.json) covers empty and unique lists, repeated values, negative and zero factors, and the int32 value boundary.

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

## TheAlgorithms reference

- [Python `is_square_free.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/is_square_free.py)
