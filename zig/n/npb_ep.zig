const std = @import("std");

const max_pairs: usize = 4096;
const modulus_mask: u64 = 70_368_744_177_663;
const word_mask: u64 = 8_388_607;
const multiplier: u64 = 1_220_703_125;
const modulus_scale: f64 = 70_368_744_177_664.0;

fn isBoundedInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and
        value >= minimum and value <= maximum;
}

fn advanceState(state: u64) u64 {
    const low = state & word_mask;
    const high = state >> 23;
    const multiplier_low = multiplier & word_mask;
    const multiplier_high = multiplier >> 23;
    const low_product = low * multiplier_low;
    const cross = (low * multiplier_high + high * multiplier_low) & word_mask;
    return (low_product + (cross << 23)) & modulus_mask;
}

export fn npb_ep(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    if (!isBoundedInteger(input[0], 1.0, @floatFromInt(max_pairs)) or
        !isBoundedInteger(input[1], 1.0, 70_368_744_177_663.0)) return -1;
    const pair_count: usize = @intFromFloat(input[0]);
    if (output_opt == null or capacity < 12) return -2;

    var state: u64 = @intFromFloat(input[1]);
    var histogram = [_]u64{0} ** 10;
    var sum_x: f64 = 0.0;
    var sum_y: f64 = 0.0;
    for (0..pair_count) |_| {
        state = advanceState(state);
        const x = 2.0 * (@as(f64, @floatFromInt(state)) / modulus_scale) - 1.0;
        state = advanceState(state);
        const y = 2.0 * (@as(f64, @floatFromInt(state)) / modulus_scale) - 1.0;
        const radius_squared = x * x + y * y;
        if (radius_squared <= 0.0 or radius_squared > 1.0) continue;
        const scale = @sqrt(-2.0 * @log(radius_squared) / radius_squared);
        const normal_x = x * scale;
        const normal_y = y * scale;
        const abs_x = if (normal_x < 0.0) -normal_x else normal_x;
        const abs_y = if (normal_y < 0.0) -normal_y else normal_y;
        const extent = @max(abs_x, abs_y);
        if (extent < 10.0) histogram[@intFromFloat(extent)] += 1;
        sum_x += normal_x;
        sum_y += normal_y;
    }
    const output = output_opt.?;
    for (0..10) |bin| output[bin] = @as(f64, @floatFromInt(histogram[bin]));
    output[10] = sum_x;
    output[11] = sum_y;
    return 12;
}
