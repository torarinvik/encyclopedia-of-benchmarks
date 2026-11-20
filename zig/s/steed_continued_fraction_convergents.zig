const MODULUS: i64 = 998244353;
const MAX_INPUT_LENGTH: usize = 19;

fn modPow(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn divisorsAreNonzero(input: [*]const i64, levels: usize) bool {
    if (input[2] == 0) return false;
    var d_value = modPow(input[2], MODULUS - 2);
    for (2..levels + 1) |level| {
        const denominator = @rem(d_value * input[2 * level + 1] + input[2 * level], MODULUS);
        if (denominator == 0) return false;
        d_value = modPow(denominator, MODULUS - 2);
    }
    return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn steed_continued_fraction_convergents(input: ?[*]const i64,
    length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const levels_value = values[0];
    if (levels_value < 1 or levels_value > 8) return -1;
    const levels: usize = @intCast(levels_value);
    if (length != 2 + 2 * levels) return -1;
    for (values[1..]) |coefficient| if (coefficient < 0 or coefficient >= MODULUS) return -1;
    if (!divisorsAreNonzero(input.?, levels)) return -1;

    const required = 8 * (levels + 2);
    if (output == null or capacity < required) return -2;
    const bytes = output.?;
    storeI64Le(bytes, 0, levels_value + 1);
    var current = values[1];
    storeI64Le(bytes, 8, current);
    var d_value = modPow(values[2], MODULUS - 2);
    var delta = values[3] * d_value % MODULUS;
    current = @rem(current + delta, MODULUS);
    storeI64Le(bytes, 16, current);
    for (2..levels + 1) |level| {
        const b_value = values[2 * level];
        const a_value = values[2 * level + 1];
        const denominator = @rem(d_value * a_value + b_value, MODULUS);
        d_value = modPow(denominator, MODULUS - 2);
        const factor = @rem(b_value * d_value + MODULUS - 1, MODULUS);
        delta = @rem(factor * delta, MODULUS);
        current = @rem(current + delta, MODULUS);
        storeI64Le(bytes, 8 * (level + 1), current);
    }
    return @intCast(required);
}
