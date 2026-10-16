const MAX_SAMPLE_COUNT: usize = 128;

fn roundThreeDecimals(value: f64) f64 {
    const bits: u64 = @bitCast(value);
    const negative = (bits >> 63) != 0;
    const exponent: i32 = @intCast((bits >> 52) & 0x7ff);
    const fraction = bits & ((@as(u64, 1) << 52) - 1);
    const significand = if (exponent == 0) fraction else fraction | (@as(u64, 1) << 52);
    const exponent2: i32 = if (exponent == 0) -1074 else exponent - 1023 - 52;
    const scaled = significand * 1000;
    var rounded: u64 = 0;
    if (exponent2 >= 0) {
        rounded = scaled << @intCast(exponent2);
    } else {
        const shift: u32 = @intCast(-exponent2);
        if (shift < 64) {
            rounded = scaled >> @intCast(shift);
            if (shift > 0) {
                const remainder = scaled & ((@as(u64, 1) << @intCast(shift)) - 1);
                const half = @as(u64, 1) << @intCast(shift - 1);
                if (remainder > half or (remainder == half and (rounded & 1) != 0)) rounded += 1;
            }
        }
    }
    const result = @as(f64, @floatFromInt(rounded)) / 1000.0;
    return if (negative) -result else result;
}

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn data_transformations(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (values == null or length < 4 or length > MAX_SAMPLE_COUNT + 2) return -1;
    const input = values.?[0..length];
    const mode = input[0];
    const count_arg = input[1];
    if ((mode != 0 and mode != 1) or count_arg < 2 or count_arg > MAX_SAMPLE_COUNT or
        length != @as(usize, @intCast(count_arg)) + 2) return -1;
    const count: usize = @intCast(count_arg);
    const sample = input[2..];
    var minimum = sample[0];
    var maximum = sample[0];
    var sum: i64 = 0;
    var sum_squares: i64 = 0;
    for (sample) |value| {
        if (value < -100000 or value > 100000) return -1;
        minimum = @min(minimum, value);
        maximum = @max(maximum, value);
        sum += value;
        sum_squares += value * value;
    }
    if (minimum == maximum) return -1;
    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    const destination = output.?[0..output_bytes];
    if (mode == 0) {
        const span: f64 = @floatFromInt(maximum - minimum);
        for (sample, 0..) |value, index| {
            const normalized = @as(f64, @floatFromInt(value - minimum)) / span;
            putF64Le(destination.ptr, index * 8, roundThreeDecimals(normalized));
        }
    } else {
        const average = @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(count));
        const variance_numerator = @as(i64, @intCast(count)) * sum_squares - sum * sum;
        const variance_denominator: f64 = @floatFromInt(count * (count - 1));
        const deviation = @sqrt(@as(f64, @floatFromInt(variance_numerator)) / variance_denominator);
        for (sample, 0..) |value, index| {
            const standardized = (@as(f64, @floatFromInt(value)) - average) / deviation;
            putF64Le(destination.ptr, index * 8, roundThreeDecimals(standardized));
        }
    }
    return @intCast(output_bytes);
}
