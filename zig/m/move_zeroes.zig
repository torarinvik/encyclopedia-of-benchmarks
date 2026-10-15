const MAX_LENGTH: usize = 4096;
const std = @import("std");

fn writeI32Le(output: [*]u8, index: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

/// Stable nonzero compaction followed by a zero-fill pass.
export fn move_zeroes(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (input[index] < std.math.minInt(i32) or input[index] > std.math.maxInt(i32)) return -1;
    }
    const output_bytes = length * 4;
    if (output_capacity < output_bytes) return -2;
    var write_index: usize = 0;
    for (0..length) |index| {
        if (input[index] != 0) { writeI32Le(output, write_index, input[index]); write_index += 1; }
    }
    while (write_index < length) { writeI32Le(output, write_index, 0); write_index += 1; }
    return @intCast(length);
}
