const std = @import("std");

const NUM_BINS = 20;
const MAX_POINTS = 4;
const MAX_INPUT_LENGTH = 26;
const PI_VALUE = 3.141592653589793238462643383279502884;

fn coordinate(input: [*c]const i64, offset: usize) f32 {
    return @as(f32, @floatFromInt(input[offset])) / 1_000_000.0;
}

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
pub export fn parboil_tpacf_cross_correlation(
    input: [*c]const i64,
    input_length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or input_length < 8 or input_length > MAX_INPUT_LENGTH) return -1;
    const data_value = input[0];
    const random_value = input[1];
    if (data_value < 1 or data_value > MAX_POINTS or random_value < 1 or random_value > MAX_POINTS) return -1;
    const data_count: usize = @intCast(data_value);
    const random_count: usize = @intCast(random_value);
    if (input_length != 2 + 3 * (data_count + random_count)) return -1;
    for (2..input_length) |i| if (input[i] < -1_000_000 or input[i] > 1_000_000) return -1;
    if (output == null or output_capacity < NUM_BINS) return -2;

    var boundaries = [_]f32{0} ** (NUM_BINS + 1);
    for (0..NUM_BINS + 1) |k| {
        const exponent = @log10(1.0) + @as(f64, @floatFromInt(k)) * 1.0 / 5.0;
        const arcminutes = std.math.pow(f64, 10.0, exponent);
        const radians = arcminutes / 60.0 * (PI_VALUE / 180.0);
        boundaries[k] = @floatCast(@cos(radians));
    }
    var histogram = [_]u8{0} ** NUM_BINS;
    const random_base = 2 + 3 * data_count;
    for (0..random_count) |j| {
        const rx = coordinate(input, random_base + 3 * j);
        const ry = coordinate(input, random_base + 3 * j + 1);
        const rz = coordinate(input, random_base + 3 * j + 2);
        for (0..data_count) |i| {
            const dx = coordinate(input, 2 + 3 * i);
            const dy = coordinate(input, 2 + 3 * i + 1);
            const dz = coordinate(input, 2 + 3 * i + 2);
            const px = dx * rx;
            const py = dy * ry;
            const pz = dz * rz;
            const xy = px + py;
            const distance = xy + pz;
            var min: usize = 0;
            var max: usize = NUM_BINS;
            while (max > min + 1) {
                const middle = (min + max) / 2;
                if (distance >= boundaries[middle]) max = middle else min = middle;
            }
            if (distance < boundaries[min] and distance >= boundaries[max]) histogram[max - 1] += 1;
        }
    }
    for (0..NUM_BINS) |bin| output[bin] = histogram[bin];
    return NUM_BINS;
}
