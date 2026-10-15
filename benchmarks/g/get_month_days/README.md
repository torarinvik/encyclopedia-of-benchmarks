# Get month days

Returns the number of days in a month using the pinned JavaScript helper and its Gregorian leap-year rule.

## Contract

- Uses the `binary_scalar` ABI with arguments `[month_number, year]`.
- Accepts month numbers 1 through 12 and years 0 through 9,999.
- Returns 31 for January, March, May, July, August, October, and December; 30 for April, June, September, and November; and 28 or 29 for February.
- February has 29 days when `year % 400 == 0` or when it is divisible by 4 but not by 100. Year 0 follows the source rule and is a leap year.
- Invalid months or years outside the bounded benchmark domain return `-1`.

## Source semantics

This follows pinned [TheAlgorithms JavaScript `GetMonthDays.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Timing-Functions/GetMonthDays.js), including its month groups and invalid-month exception, which the ABI maps to `-1`. The source imports [TheAlgorithms JavaScript `LeapYear.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LeapYear.js), whose predicate is `year % 400 === 0 || (year % 100 !== 0 && year % 4 === 0)`. The package restricts the input year to integer values 0..9,999; within that domain, the ports preserve the source's predicate. This differs from the standalone `leap_year` benchmark because this operation returns month length rather than a boolean.

## Workload and build

[`workload.json`](workload.json) covers each month-length category, century leap-year behavior, year zero, and invalid arguments. Build and record with the binary-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm get_month_days --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/g/get_month_days/rust/build.json
```

The nine implementations are in `c/g/get_month_days.c`, `c3/g/get_month_days.c3`, `cpp/g/get_month_days.cpp`, `elisa/g/get_month_days.elisa`, `nim/g/get_month_days.nim`, `odin/g/get_month_days.odin`, `rust/g/get_month_days.rs`, `v/g/get_month_days.v`, and `zig/g/get_month_days.zig`.
