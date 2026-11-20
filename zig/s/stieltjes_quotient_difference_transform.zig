const MODULUS: i64 = 998244353;
const MAX_WORDS: usize = 11;
const TABLE_COLUMNS: usize = 9;

fn normalize(value: i64) i64 {
    const reduced = @rem(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn multiply(left: i64, right: i64) i64 { return @rem(left * right, MODULUS); }

fn power(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn stieltjes_quotient_difference_transform(
    input: [*c]const i64,
    input_length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or input_length < 3 or input_length > MAX_WORDS) return -1;
    const count_value = input[0];
    if (count_value < 2 or count_value > 9 or input_length != @as(usize, @intCast(count_value + 1))) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |i| if (input[i + 1] <= 0 or input[i + 1] >= MODULUS) return -1;

    var q = [_]i64{0} ** 45;
    var e = [_]i64{0} ** 45;
    for (0..count - 1) |k|
        q[TABLE_COLUMNS + k] = multiply(input[k + 2], power(input[k + 1], MODULUS - 2));
    var j: usize = 1;
    while (j <= 4) : (j += 1) {
        const last_e = @as(i64, @intCast(count)) - 2 * @as(i64, @intCast(j)) - 1;
        if (last_e < 0) break;
        for (0..@as(usize, @intCast(last_e + 1))) |k|
            e[j * TABLE_COLUMNS + k] = normalize(e[(j - 1) * TABLE_COLUMNS + k + 1] + q[j * TABLE_COLUMNS + k + 1] - q[j * TABLE_COLUMNS + k]);
        const last_q = @as(i64, @intCast(count)) - 2 * @as(i64, @intCast(j)) - 2;
        if (last_q >= 0) {
            for (0..@as(usize, @intCast(last_q + 1))) |k| {
                const pivot = e[j * TABLE_COLUMNS + k];
                if (pivot == 0) return -1;
                const product = multiply(q[j * TABLE_COLUMNS + k + 1], e[j * TABLE_COLUMNS + k + 1]);
                q[(j + 1) * TABLE_COLUMNS + k] = multiply(product, power(pivot, MODULUS - 2));
            }
        }
    }

    const required = 8 * (count + 1);
    if (output == null or output_capacity < required) return -2;
    storeI64(output, 0, count_value);
    for (1..count) |index| {
        const value = if (index % 2 == 1) q[((index + 1) / 2) * TABLE_COLUMNS] else e[(index / 2) * TABLE_COLUMNS];
        storeI64(output, 8 * index, value);
    }
    return @intCast(required);
}
