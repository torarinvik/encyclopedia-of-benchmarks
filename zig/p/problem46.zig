const MAX_ODD_COMPOSITE: i64 = 99_999;

fn is_prime(number: i64) bool {
    if (number < 2) return false;
    if (number < 4) return true;
    if (@mod(number, 2) == 0 or @mod(number, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor <= @divTrunc(number, divisor)) : (divisor += 6) {
        if (@mod(number, divisor) == 0 or @mod(number, divisor + 2) == 0) return false;
    }
    return true;
}

fn find_first_counterexample() i64 {
    var candidate: i64 = 3;
    while (candidate <= MAX_ODD_COMPOSITE) : (candidate += 2) {
        if (is_prime(candidate)) continue;
        var represented = false;
        var square: i64 = 0;
        while (2 * square * square <= candidate) : (square += 1) {
            if (is_prime(candidate - 2 * square * square)) {
                represented = true;
                break;
            }
        }
        if (!represented) return candidate;
    }
    return -1;
}

export fn problem46(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    return find_first_counterexample();
}
