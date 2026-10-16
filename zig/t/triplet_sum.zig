fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 255);
    }
}

fn sortThree(values: *[3]i64) void {
    if (values[0] > values[1]) std.mem.swap(i64, &values[0], &values[1]);
    if (values[1] > values[2]) std.mem.swap(i64, &values[1], &values[2]);
    if (values[0] > values[1]) std.mem.swap(i64, &values[0], &values[1]);
}

const std = @import("std");

pub export fn triplet_sum(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    const max_items: usize = 10;
    if (input == null or length < 1 or length > max_items + 1) return -1;
    const target = input[0];
    if (target < -3_000_000 or target > 3_000_000) return -1;
    const item_count = length - 1;
    for (0..item_count) |index| {
        const value = input[index + 1];
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }
    if (output_capacity < 24 or output == null) return -2;

    var result = [_]i64{ 0, 0, 0 };
    var found = false;
    for (0..item_count) |first| {
        if (found) break;
        for (0..item_count) |second| {
            if (found) break;
            if (second == first) continue;
            for (0..item_count) |third| {
                if (third == first or third == second) continue;
                const a = input[first + 1];
                const b = input[second + 1];
                const c = input[third + 1];
                if (a + b + c == target) {
                    result = .{ a, b, c };
                    sortThree(&result);
                    found = true;
                    break;
                }
            }
        }
    }
    for (0..3) |index| putI64Le(output, index * 8, result[index]);
    return 3;
}
