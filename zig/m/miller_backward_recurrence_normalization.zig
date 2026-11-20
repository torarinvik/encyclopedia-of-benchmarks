const MODULUS: i64 = 998244353;
const MAX_INPUT_LENGTH: usize = 35;

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

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn miller_backward_recurrence_normalization(input: ?[*]const i64,
    length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const levels_value = values[0];
    if (levels_value < 1 or levels_value > 8) return -1;
    const levels: usize = @intCast(levels_value);
    if (length != 4 * levels + 2) return -1;
    for (values[1..]) |coefficient| {
        if (coefficient < 0 or coefficient >= MODULUS) return -1;
    }
    for (1..levels + 1) |level| {
        if (values[3 * level] == 0) return -1;
    }

    var trial: [10]i64 = @splat(0);
    trial[levels] = 1;
    trial[levels + 1] = 0;
    var level = levels;
    while (level > 0) : (level -= 1) {
        const a_value = values[3 * level - 2];
        const b_value = values[3 * level - 1];
        const c_value = values[3 * level];
        const positive = @rem(b_value * trial[level], MODULUS);
        const negative = @rem(a_value * trial[level + 1], MODULUS);
        const numerator = @rem(positive + MODULUS - negative, MODULUS);
        trial[level - 1] = @rem(numerator * modPow(c_value, MODULUS - 2), MODULUS);
    }
    const lambda_start = 3 * levels + 1;
    var normalizer: i64 = 0;
    for (0..levels + 1) |index| {
        normalizer = @rem(normalizer + values[lambda_start + index] * trial[index], MODULUS);
    }
    if (normalizer == 0) return -1;
    const scale = modPow(normalizer, MODULUS - 2);
    const required = 8 * (levels + 2);
    if (output == null or capacity < required) return -2;

    const bytes = output.?;
    storeI64Le(bytes, 0, levels_value);
    for (0..levels + 1) |index| {
        storeI64Le(bytes, 8 * (index + 1), @rem(trial[index] * scale, MODULUS));
    }
    return @intCast(required);
}
