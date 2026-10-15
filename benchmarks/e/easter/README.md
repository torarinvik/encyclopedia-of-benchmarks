# Easter date

## Contract

For a year `year` in the Gregorian calendar, return the Gregorian Easter date packed as `month * 100 + day` (for example, April 20 is `420`). The exported C ABI entry point is:

```c
int64_t easter(int64_t year);
```

The benchmark accepts years `0` through `9999`. Values below zero or above `9999` return `-1`. Following the pinned C++ source, every year through `1582` returns `0`, representing its `(year, month, day) = (0, 0, 0)` sentinel. For later years, the implementation applies the same Gregorian computus arithmetic and returns the packed month/day. It does not validate historical adoption of the Gregorian calendar or add calendar-specific exceptions.

The source stores the answer as a year/month/day structure. The benchmark packs its month and day into one signed 64-bit result to use the scalar ABI; the year is already the input. The year bound keeps intermediate arithmetic small and the output exact.

## Workload

[`workload.json`](workload.json) includes the source's published years, the cutoff, representative modern years, and out-of-range inputs. It uses the shared scalar ABI family with one signed 64-bit input and result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/easter.c`](../../../c/e/easter.c) |
| C3 | [`c3/e/easter.c3`](../../../c3/e/easter.c3) |
| C++ | [`cpp/e/easter.cpp`](../../../cpp/e/easter.cpp) |
| Elisa | [`elisa/e/easter.elisa`](../../../elisa/e/easter.elisa) |
| Nim | [`nim/e/easter.nim`](../../../nim/e/easter.nim) |
| Odin | [`odin/e/easter.odin`](../../../odin/e/easter.odin) |
| Rust | [`rust/e/easter.rs`](../../../rust/e/easter.rs) |
| V | [`v/e/easter.v`](../../../v/e/easter.v) |
| Zig | [`zig/e/easter.zig`](../../../zig/e/easter.zig) |

## Pinned sources

- [C++ `easter.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/easter.cpp)
- [C++ additional repository `easter.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/easter.cpp)
