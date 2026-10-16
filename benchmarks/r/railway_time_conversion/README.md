# Railway time conversion

This package ports the pinned JavaScript RailwayTimeConversion function. It converts normalized 12-hour clock text to 24-hour text.

## Contract

- Input is a signed i64 array laid out as [10, ASCII bytes...], where the ten bytes are hh:mm:ssAM or hh:mm:ssPM.
- Valid hours are 01 through 12; minutes and seconds are 00 through 59; separators are colons and the uppercase suffix is AM or PM.
- Output is exactly eight ASCII bytes in HH:MM:SS format. Noon remains 12, midnight becomes 00, and other PM hours add twelve.
- Malformed input, a null input pointer, or any array length other than eleven values returns -1 without writing output. An output capacity smaller than eight bytes, or a null output pointer for a valid time, returns -2 without writing output.
- The pinned source assumes a normalized time string. The adapter rejects malformed or out-of-domain strings before conversion.

## Workload and oracle

[workload.json](workload.json) covers the pinned example, AM/PM boundaries, leading zeroes, short output capacity, and malformed fields and array lengths. The independent oracle is [railway_time_conversion_oracle.py](../../railway_time_conversion_oracle.py).

Pinned source: [TheAlgorithms/JavaScript RailwayTimeConversion.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RailwayTimeConversion.js).

## Running and verifying

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm railway_time_conversion --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm railway_time_conversion

Verify a selected port with:

    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm railway_time_conversion --languages rust

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/railway_time_conversion.c](../../../c/r/railway_time_conversion.c) |
| C3 | [c3/r/railway_time_conversion.c3](../../../c3/r/railway_time_conversion.c3) |
| C++ | [cpp/r/railway_time_conversion.cpp](../../../cpp/r/railway_time_conversion.cpp) |
| Elisa | [elisa/r/railway_time_conversion.elisa](../../../elisa/r/railway_time_conversion.elisa) |
| Nim | [nim/r/railway_time_conversion.nim](../../../nim/r/railway_time_conversion.nim) |
| Odin | [odin/r/railway_time_conversion.odin](../../../odin/r/railway_time_conversion.odin) |
| Rust | [rust/r/railway_time_conversion.rs](../../../rust/r/railway_time_conversion.rs) |
| V | [v/r/railway_time_conversion.v](../../../v/r/railway_time_conversion.v) |
| Zig | [zig/r/railway_time_conversion.zig](../../../zig/r/railway_time_conversion.zig) |
