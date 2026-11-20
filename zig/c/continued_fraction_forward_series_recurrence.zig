const MODULUS: i64 = 998244353;
const MAX_INPUT_LENGTH: usize = 11;

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

fn nextNumerator(coefficient: i64, rho: i64) i64 {
    return @rem(coefficient * @rem(rho + 1, MODULUS), MODULUS);
}

fn divisorsAreNonzero(input: [*]const i64, count: usize) bool {
    var rho: i64 = 0;
    for (1..count) |index| {
        const top = nextNumerator(input[index + 1], rho);
        const denominator = @rem(1 + MODULUS - top, MODULUS);
        if (denominator == 0) return false;
        rho = @rem(top * modPow(denominator, MODULUS - 2), MODULUS);
    }
    return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn continued_fraction_forward_series_recurrence(input: ?[*]const i64,
    length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 2 or count_value > 9) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (values[1..]) |coefficient| if (coefficient < 0 or coefficient >= MODULUS) return -1;
    if (!divisorsAreNonzero(input.?, count)) return -1;
    const required = 8 * (count + 1);
    if (output == null or capacity < required) return -2;

    const bytes = output.?;
    storeI64Le(bytes, 0, count_value);
    var rho: i64 = 0;
    var term = values[1];
    var total = term;
    storeI64Le(bytes, 8, total);
    for (1..count) |index| {
        const top = nextNumerator(values[index + 1], rho);
        const denominator = @rem(1 + MODULUS - top, MODULUS);
        rho = @rem(top * modPow(denominator, MODULUS - 2), MODULUS);
        term = @rem(rho * term, MODULUS);
        total = @rem(total + term, MODULUS);
        storeI64Le(bytes, 8 * (index + 1), total);
    }
    return @intCast(required);
}
