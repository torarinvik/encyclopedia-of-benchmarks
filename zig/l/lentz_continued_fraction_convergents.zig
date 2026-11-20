const MAX_TERMS: usize = 8;
const MAX_INPUT_LENGTH: usize = 19;
const MODULUS: i64 = 998244353;

fn normalize(value: i64) i64 {
    const reduced = @mod(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn power(base_input: i64, exponent_input: i64) i64 {
    var base = normalize(base_input);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lentz_continued_fraction_convergents(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_TERMS))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;
    for (1..length) |i| if (input[i] < 0 or input[i] >= MODULUS) return -1;
    var value = input[1];
    if (value == 0) return -1;
    var c_ratio = value;
    var d_ratio: i64 = 0;
    var trace: [MAX_TERMS + 2]i64 = @splat(0);
    trace[0] = value;
    for (0..count) |index| {
        const numerator = input[2 + 2 * index];
        const denominator = input[3 + 2 * index];
        const d_denominator = normalize(denominator + numerator * d_ratio);
        if (d_denominator == 0 or c_ratio == 0) return -1;
        const c_value = normalize(denominator + numerator * power(c_ratio, MODULUS - 2));
        if (c_value == 0) return -1;
        d_ratio = power(d_denominator, MODULUS - 2);
        value = @mod(value * c_value, MODULUS) * d_ratio % MODULUS;
        c_ratio = c_value;
        trace[index + 1] = value;
    }
    const output_bytes = 8 * (count + 2);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(count + 1));
    for (0..count + 1) |i| storeI64Le(output, 8 * (i + 1), trace[i]);
    return @intCast(output_bytes);
}
