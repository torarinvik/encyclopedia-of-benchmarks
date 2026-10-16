# Parse date

## Contract

Input is `[byte_length, ASCII date bytes...]` in the exact format `d/m/yyyy`: one or two decimal digits for day, one or two for month, and exactly four for year, with literal slash separators and no whitespace. The parsed date is returned as `year*10000 + month*100 + day`. Invalid formats or calendar dates return `-1`.

Month lengths use the Gregorian leap-year rule. The bounded format admits year `0000`, which the pinned helper treats as a leap year. The benchmark accepts only ASCII and maps the source's thrown errors to `-1`.

## Source review

The pinned JavaScript parser matches `^(\\d{1,2})/(\\d{1,2})/(\\d{4})$`, parses day/month/year, and checks that the day is within `getMonthDays(month, year)`. Its helper accepts months 1–12 and applies the Gregorian leap-year predicate. The benchmark exposes the parsed fields through a scalar encoding and keeps the parser's format constraints explicit.

Pinned sources: [JavaScript `ParseDate.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Timing-Functions/ParseDate.js) and [JavaScript `GetMonthDays.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Timing-Functions/GetMonthDays.js).

## Workload and implementations

[`workload.json`](workload.json) covers short fields, leap days, leap-century behavior, month limits, exact format enforcement, and malformed dates. The [runtime oracle](../../parse_date_oracle.py) implements the same bounded parser.

| Language | Port |
|---|---|
| C | [`c/p/parse_date.c`](../../../c/p/parse_date.c) |
| C3 | [`c3/p/parse_date.c3`](../../../c3/p/parse_date.c3) |
| C++ | [`cpp/p/parse_date.cpp`](../../../cpp/p/parse_date.cpp) |
| Elisa | [`elisa/p/parse_date.elisa`](../../../elisa/p/parse_date.elisa) |
| Nim | [`nim/p/parse_date.nim`](../../../nim/p/parse_date.nim) |
| Odin | [`odin/p/parse_date.odin`](../../../odin/p/parse_date.odin) |
| Rust | [`rust/p/parse_date.rs`](../../../rust/p/parse_date.rs) |
| V | [`v/p/parse_date.v`](../../../v/p/parse_date.v) |
| Zig | [`zig/p/parse_date.zig`](../../../zig/p/parse_date.zig) |
