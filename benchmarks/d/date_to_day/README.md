# Date to day

Parse a Gregorian date written as `d/m/yyyy` or `dd/mm/yyyy` and return its English weekday name.

## Contract

- ABI: signed i64 array to byte output. Input is the date's ASCII bytes followed by one terminal `0`; output is the weekday name's ASCII bytes with no terminator.
- Day and month use one or two decimal digits. The year uses exactly four digits and is restricted to 0001 through 9999. The date must exist in the Gregorian calendar.
- The pinned JavaScript parser accepts the four-digit year `0000`; this benchmark narrows the input domain to years 0001–9999 to match common Gregorian date libraries and the independent oracle.
- Invalid input returns `-1`. If the output pointer is null or capacity is smaller than the weekday name, return `-2` without writing output.

## Source and workload

This package follows [TheAlgorithms/JavaScript `DateToDay.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/DateToDay.js) and its pinned `ParseDate`, `GetMonthDays`, and `LeapYear` dependencies from the same commit. The ports preserve the source's weekday calculation and Saturday-first name mapping. The independent oracle uses Python's Gregorian calendar implementation.

[`workload.json`](workload.json) covers the source example, one- and two-digit date fields, leap days and century rules, year bounds, malformed encodings, nonexistent dates, and insufficient output capacity.

Build and verify Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm date_to_day --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/date_to_day/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm date_to_day --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/date_to_day.c`](../../../c/d/date_to_day.c) |
| C3 | [`c3/d/date_to_day.c3`](../../../c3/d/date_to_day.c3) |
| C++ | [`cpp/d/date_to_day.cpp`](../../../cpp/d/date_to_day.cpp) |
| Elisa | [`elisa/d/date_to_day.elisa`](../../../elisa/d/date_to_day.elisa) |
| Nim | [`nim/d/date_to_day.nim`](../../../nim/d/date_to_day.nim) |
| Odin | [`odin/d/date_to_day.odin`](../../../odin/d/date_to_day.odin) |
| Rust | [`rust/d/date_to_day.rs`](../../../rust/d/date_to_day.rs) |
| V | [`v/d/date_to_day.v`](../../../v/d/date_to_day.v) |
| Zig | [`zig/d/date_to_day.zig`](../../../zig/d/date_to_day.zig) |
