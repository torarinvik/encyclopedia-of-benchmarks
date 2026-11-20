const MAX_WORDS: usize = 16;
const OUTPUT_BYTES: usize = 16;

fn gcd(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn storeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn levin_partial_sum_transform(
    input: [*c]const i64,
    input_length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or input_length < 5 or input_length > MAX_WORDS) return -1;
    const n_value = input[0];
    const k_value = input[1];
    if (n_value < 0 or n_value > 8 or k_value < 1 or k_value > 3) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (input_length != n + k + 4) return -1;
    const term_count = n + k + 2;
    for (0..term_count) |index| {
        const term = input[index + 2];
        if (term == 0 or term < -3 or term > 3) return -1;
    }

    var product: i64 = 1;
    for (0..k + 1) |j| product *= input[n + j + 3];
    var numerator: i64 = 0;
    var denominator: i64 = 0;
    for (0..k + 1) |j| {
        var choose: i64 = 1;
        for (1..j + 1) |r| {
            choose = @divTrunc(choose * @as(i64, @intCast(k - r + 1)), @as(i64, @intCast(r)));
        }
        var power: i64 = 1;
        for (0..k - 1) |_| power *= @as(i64, @intCast(n + j + 1));
        const term = input[n + j + 3];
        var weight = choose * power * @divTrunc(product, term);
        if (j % 2 == 1) weight = -weight;
        var partial: i64 = 0;
        for (0..n + j + 1) |index| partial += input[index + 2];
        numerator += weight * partial;
        denominator += weight;
    }
    if (denominator == 0) return -1;
    if (denominator < 0) {
        numerator = -numerator;
        denominator = -denominator;
    }
    const magnitude = if (numerator < 0) -numerator else numerator;
    const divisor = gcd(magnitude, denominator);
    numerator = @divTrunc(numerator, divisor);
    denominator = @divTrunc(denominator, divisor);
    if (output == null or output_capacity < OUTPUT_BYTES) return -2;
    storeI64(output, 0, numerator);
    storeI64(output, 8, denominator);
    return OUTPUT_BYTES;
}
