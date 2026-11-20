const MAX_TERMS: usize = 16;
const MAX_WORDS: usize = 18;
const VALUE_LIMIT: i64 = 1_000_000;
const OUTPUT_BYTES: usize = 16;

fn euler_gcd(left_value: u64, right_value: u64) u64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn euler_store_i64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn euler_alternating_series_transform(values: [*c]const i64,
    length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_WORDS) return -1;
    const n_value = values[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_TERMS)) or
        length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    for (0..n) |index| {
        const value = values[index + 1];
        if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
    }
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;

    var numerator: i64 = 0;
    for (0..n) |order| {
        var difference: i64 = 0;
        var coefficient: i64 = 1;
        for (0..order + 1) |index| {
            const term = values[order - index + 1];
            if (index % 2 == 0) {
                difference += coefficient * term;
            } else {
                difference -= coefficient * term;
            }
            if (index < order) {
                coefficient = coefficient * @as(i64, @intCast(order - index)) /
                    @as(i64, @intCast(index + 1));
            }
        }
        const weight: i64 = @as(i64, 1) << @intCast(n - order - 1);
        const weighted = difference * weight;
        if (order % 2 == 0) {
            numerator += weighted;
        } else {
            numerator -= weighted;
        }
    }

    var denominator: i64 = @as(i64, 1) << @intCast(n);
    const magnitude: u64 = @intCast(if (numerator < 0) -numerator else numerator);
    const divisor = euler_gcd(magnitude, @intCast(denominator));
    numerator = @divExact(numerator, @as(i64, @intCast(divisor)));
    denominator = @divExact(denominator, @as(i64, @intCast(divisor)));
    euler_store_i64(output, 0, numerator);
    euler_store_i64(output, 8, denominator);
    return @intCast(OUTPUT_BYTES);
}
