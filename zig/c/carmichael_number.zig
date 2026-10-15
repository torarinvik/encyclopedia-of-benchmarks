fn is_composite(n: i64) bool {
    if (n < 4) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(n, divisor)) : (divisor += 1) {
        if (@rem(n, divisor) == 0) return true;
    }
    return false;
}

fn modular_power(base: i64, exponent: i64, modulus: i64) i64 {
    if (exponent == 0) return 1;
    const half = @rem(modular_power(base, @divTrunc(exponent, 2), modulus), modulus);
    var result = @rem(half * half, modulus);
    if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
    return result;
}

fn gcd(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn carmichael_number(value: i64) i64 {
    if (value < 1 or value > 10000) return -1;
    if (value < 3 or !is_composite(value)) return 0;
    var base: i64 = 2;
    while (base < value) : (base += 1) {
        if (gcd(base, value) == 1 and modular_power(base, value - 1, value) != 1) return 0;
    }
    return 1;
}
