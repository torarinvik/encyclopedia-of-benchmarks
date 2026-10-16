# Find month calendar

## Contract

The pinned JavaScript code accepts a month string in mm/yyyy form and prints a calendar. The benchmark normalizes that input to exactly two signed 64-bit values: [month, year]. Month is 1 through 12 and year is 1899 through 2100.

The calendar uses the Gregorian leap-year rule and the pinned source's Monday 1 January 1900 epoch. Its heading and padded rows are emitted as ASCII, with one LF after every console.log line, including the last line. Each ABI call uses fresh month state because the JavaScript Month.getDayDiff method mutates its epoch object.

The C ABI returns the number of bytes written. Invalid input returns -1. A null output buffer or insufficient capacity returns -2 after input validation. The largest valid result is 181 bytes.

    int64_t find_month_calendar(const int64_t *values, size_t length,
                                uint8_t *output, size_t output_capacity);

## Workload

workload.json includes epoch and reverse-epoch dates, leap and common February cases, the pinned 1/2021 example, invalid dates and layouts, exact maximum output, and insufficient output capacity. The source-derived oracle is ../../find_month_calendar_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/find_month_calendar.c](../../../c/f/find_month_calendar.c) |
| C3 | [c3/f/find_month_calendar.c3](../../../c3/f/find_month_calendar.c3) |
| C++ | [cpp/f/find_month_calendar.cpp](../../../cpp/f/find_month_calendar.cpp) |
| Elisa | [elisa/f/find_month_calendar.elisa](../../../elisa/f/find_month_calendar.elisa) |
| Nim | [nim/f/find_month_calendar.nim](../../../nim/f/find_month_calendar.nim) |
| Odin | [odin/f/find_month_calendar.odin](../../../odin/f/find_month_calendar.odin) |
| Rust | [rust/f/find_month_calendar.rs](../../../rust/f/find_month_calendar.rs) |
| V | [v/f/find_month_calendar.v](../../../v/f/find_month_calendar.v) |
| Zig | [zig/f/find_month_calendar.zig](../../../zig/f/find_month_calendar.zig) |

## Pinned source

- [JavaScript FindMonthCalendar.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/FindMonthCalendar.js)
- [JavaScript LeapYear.js dependency](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LeapYear.js)

This package is separate from date-to-weekday and month-length benchmarks: it returns the complete weekday-aligned text grid, including the source's labels, four-character cells, and line endings. Run all ports with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm find_month_calendar --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 --jobs 4`.
