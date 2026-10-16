fn is_prime(value: i64) bool {
    if (value < 2) return false;
    if (value == 2 or value == 3) return true;
    if (@mod(value, 2) == 0 or @mod(value, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 6) {
        if (@mod(value, divisor) == 0 or @mod(value, divisor + 2) == 0) return false;
    }
    return true;
}

fn is_truncatable_prime(value: i64) bool {
    if (!is_prime(value)) return false;
    var power: i64 = 10;
    while (power < value) : (power *= 10) {
        if (!is_prime(@divTrunc(value, power)) or !is_prime(@rem(value, power))) return false;
    }
    return true;
}

export fn problem37(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var found: i64 = 0;
    var sum: i64 = 0;
    var candidate: i64 = 13;
    while (candidate <= 1_000_000 and found < 11) : (candidate += 2) {
        if (is_truncatable_prime(candidate)) {
            sum += candidate;
            found += 1;
        }
    }
    return if (found == 11) sum else -1;
}
