const MAX_MULTIPLIER: i64 = 950_560;

fn is_prime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn all_chernick_factors_are_prime(n: i64, multiplier: i64) bool {
    if (!is_prime(6 * multiplier + 1) or !is_prime(12 * multiplier + 1)) {
        return false;
    }

    var factor: i64 = 18 * multiplier + 1;
    var index: i64 = 1;
    while (index <= n - 2) : (index += 1) {
        if (!is_prime(factor)) return false;
        if (index < n - 2) factor = 2 * (factor - 1) + 1;
    }
    return true;
}

export fn chernick_carmichael_least_multiplier(
    input: [*c]const i64,
    length: usize,
) i64 {
    if (input == null or length != 1) return -1;
    const n = input[0];
    if (n < 3 or n > 9) return -1;

    var step: i64 = 1;
    var shift_count: i64 = 0;
    if (n > 4) shift_count = n - 4;
    while (shift_count > 0) : (shift_count -= 1) {
        step *= 2;
    }
    if (n > 5) step *= 5;

    var multiplier = step;
    while (multiplier <= MAX_MULTIPLIER) : (multiplier += step) {
        if (all_chernick_factors_are_prime(n, multiplier)) return multiplier;
    }
    return -1;
}
