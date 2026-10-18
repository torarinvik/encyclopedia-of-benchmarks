const MIN_MODULUS: i64 = 2;
const MAX_MODULUS: i64 = 255;
const MIN_ATTEMPTS: i64 = 1;
const MAX_ATTEMPTS: i64 = 16;
const INVALID_RESULT: i64 = -1;

fn gcdI64(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @mod(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

export fn shors_algorithm(packed: ?[*]const i64, length: usize) i64 {
    if (packed == null or length < 3 or length > 19) return INVALID_RESULT;
    const values = packed.?;
    const modulus = values[0];
    const attempts = values[1];
    if (modulus < MIN_MODULUS or modulus > MAX_MODULUS or
        attempts < MIN_ATTEMPTS or attempts > MAX_ATTEMPTS or
        length != @as(usize, @intCast(2 + attempts))) return INVALID_RESULT;
    for (0..@as(usize, @intCast(attempts))) |index| {
        const base = values[2 + index];
        if (base < 2 or base > modulus) return INVALID_RESULT;
    }

    for (0..@as(usize, @intCast(attempts))) |index| {
        const base = values[2 + index];
        const common = gcdI64(base, modulus);
        if (common != 1) return common;
        var order: i64 = 1;
        var power = @mod(base, modulus);
        while (power != 1 and order < modulus - 1) {
            power = @mod(power * base, modulus);
            order += 1;
        }
        if (power != 1) return INVALID_RESULT;
        if (@mod(order, 2) == 1) continue;

        var half_power: i64 = 1;
        for (0..@as(usize, @intCast(order / 2))) |_| {
            half_power = @mod(half_power * base, modulus);
        }
        const upper = half_power + 1;
        const lower = half_power - 1;
        if (@mod(upper, modulus) == 0 or @mod(lower, modulus) == 0) continue;
        const upper_gcd = gcdI64(upper, modulus);
        if (upper_gcd != 1) return upper_gcd;
        return gcdI64(lower, modulus);
    }
    return INVALID_RESULT;
}
