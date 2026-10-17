const std = @import("std");

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits = @as(u64, @bitCast(value));
    for (0..8) |index| {
        const shift: u6 = @intCast(index * 8);
        output[offset + index] = @truncate(bits >> shift);
    }
}

export fn shree_dharacharya_formula(input: [*c]const i64, length: usize,
                                    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    for (0..3) |index| {
        if (input[index] < -1_000_000 or input[index] > 1_000_000) return -1;
    }
    if (input[0] == 0) return -1;
    const a: f64 = @floatFromInt(input[0]);
    const b: f64 = @floatFromInt(input[1]);
    const c: f64 = @floatFromInt(input[2]);
    const discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return -1;
    if (output == null or capacity < 16) return -2;
    const root = @sqrt(discriminant);
    const denominator = 2.0 * a;
    const first = (-b + root) / denominator;
    const second = (-b - root) / denominator;
    writeF64Le(output, 0, first);
    writeF64Le(output, 8, second);
    return 16;
}
