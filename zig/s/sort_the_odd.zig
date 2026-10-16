const std = @import("std");

const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

export fn sort_the_odd_benchmark(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (input == null and length != 0)) return -1;

    var odds: [MAX_LENGTH]i64 = undefined;
    var odd_count: usize = 0;
    for (0..length) |i| {
        const value = input[i];
        if (value < MIN_VALUE or value > MAX_VALUE) return -1;
        if (@rem(value, 2) != 0) {
            odds[odd_count] = value;
            odd_count += 1;
        }
    }
    std.mem.sort(i64, odds[0..odd_count], {}, std.sort.asc(i64));

    var odd_index: usize = 0;
    var checksum: i64 = 0;
    for (0..length) |i| {
        var value = input[i];
        if (@rem(value, 2) != 0) {
            value = odds[odd_index];
            odd_index += 1;
        }
        checksum += @as(i64, @intCast(i + 1)) * (value + CHECKSUM_OFFSET);
    }
    return checksum;
}
