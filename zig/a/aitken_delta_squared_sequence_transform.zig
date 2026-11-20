const MAX_TERMS: usize = 64;
const MAX_WORDS: usize = 66;
const VALUE_LIMIT: i64 = 1_000_000;

fn aitken_gcd(left_value: u64, right_value: u64) u64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn aitken_store_i64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn aitken_delta_squared_sequence_transform(values: [*c]const i64,
    length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_WORDS) return -1;
    const n_value = values[0];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_TERMS)) or
        length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    for (0..n) |index| {
        const value = values[index + 1];
        if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
    }
    const output_length = 16 * (n - 2);
    if (output == null or output_capacity < output_length) return -2;

    for (0..n - 2) |index| {
        const first = values[index + 1];
        const middle = values[index + 2];
        const last = values[index + 3];
        var numerator = first * last - middle * middle;
        var denominator = first - 2 * middle + last;
        if (denominator == 0) {
            if (first == middle and middle == last) {
                numerator = first;
                denominator = 1;
            } else {
                numerator = 0;
            }
        } else {
            if (denominator < 0) {
                numerator = -numerator;
                denominator = -denominator;
            }
            const magnitude: u64 = @intCast(if (numerator < 0) -numerator else numerator);
            const divisor = aitken_gcd(magnitude, @intCast(denominator));
            numerator = @divExact(numerator, @as(i64, @intCast(divisor)));
            denominator = @divExact(denominator, @as(i64, @intCast(divisor)));
        }
        aitken_store_i64(output, index * 16, numerator);
        aitken_store_i64(output, index * 16 + 8, denominator);
    }
    return @intCast(output_length);
}
