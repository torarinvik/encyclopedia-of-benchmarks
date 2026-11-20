# Gregorian day count to ordinal date

Convert a bounded signed day offset from the Unix civil epoch into a calendar
year and one-based day of year. The primary uses constant-time 400-year era
decomposition; the independent reference binary-searches Gregorian year starts.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `gregorian_daycount_to_ordinal_date`.
- Input is exactly `[day_offset]`, where the offset is in `[-146097,146097]`.
- Day offset zero denotes 1970-01-01. The calendar is proleptic Gregorian with
  astronomical year numbering.
- Success writes two little-endian signed-i64 values: `(year, ordinal_day)`.
  The ordinal is one-based and ranges from 1 through 365 or 366.
- Invalid/null input returns `-1`; null or short output returns `-2`. Input is
  fully validated before capacity checks, and errors leave output untouched.
- Maximum input lengths are 1 valid and 2 parseable words. Maximum output is
  16 bytes; declared workspace is 256 bytes.

The accepted interval covers exactly 400 years on either side of the epoch:
the first offset maps to 1570-01-01 and the last to 2370-01-01. This bounded
profile measures day-count decoding and ordinal derivation, not time zones,
historical calendar cutovers, or locale formatting.

## Algorithm and references

The primary converts the offset to a civil date by shifting the epoch to a
March-based year, splitting into 400-year eras, then recovering year-of-era,
month, and day. It converts the resulting month/day to a one-based ordinal.
The independent reference uses an absolute proleptic-Gregorian year-start
formula and binary-searches the unique year interval containing the target day.

Method references: Howard Hinnant, [civil-date algorithms](https://howardhinnant.github.io/date_algorithms.html), and the U.S. Naval Observatory's [Julian-day conversion notes](https://aa.usno.navy.mil/faq/JD_formula.html). The pinned RosettaCodeData [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) supplied title discovery only; its task text, code, examples, and tests were not used.

See [RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and
[workload.json](workload.json).

| Language | Source |
| --- | --- |
| C | [c/g/gregorian_daycount_to_ordinal_date.c](../../../c/g/gregorian_daycount_to_ordinal_date.c) |
| C3 | [c3/g/gregorian_daycount_to_ordinal_date.c3](../../../c3/g/gregorian_daycount_to_ordinal_date.c3) |
| C++ | [cpp/g/gregorian_daycount_to_ordinal_date.cpp](../../../cpp/g/gregorian_daycount_to_ordinal_date.cpp) |
| Elisa | [elisa/g/gregorian_daycount_to_ordinal_date.elisa](../../../elisa/g/gregorian_daycount_to_ordinal_date.elisa) |
| Mojo | [mojo/g/gregorian_daycount_to_ordinal_date.mojo](../../../mojo/g/gregorian_daycount_to_ordinal_date.mojo) |
| Nim | [nim/g/gregorian_daycount_to_ordinal_date.nim](../../../nim/g/gregorian_daycount_to_ordinal_date.nim) |
| Odin | [odin/g/gregorian_daycount_to_ordinal_date.odin](../../../odin/g/gregorian_daycount_to_ordinal_date.odin) |
| Rust | [rust/g/gregorian_daycount_to_ordinal_date.rs](../../../rust/g/gregorian_daycount_to_ordinal_date.rs) |
| V | [v/g/gregorian_daycount_to_ordinal_date.v](../../../v/g/gregorian_daycount_to_ordinal_date.v) |
| Zig | [zig/g/gregorian_daycount_to_ordinal_date.zig](../../../zig/g/gregorian_daycount_to_ordinal_date.zig) |
