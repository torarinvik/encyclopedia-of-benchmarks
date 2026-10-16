fn is_prime(value: i64) bool {
    if (value < 2) return false;
    if (value < 4) return true;
    if (@mod(value, 2) == 0 or @mod(value, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 6) {
        if (@mod(value, divisor) == 0 or @mod(value, divisor + 2) == 0) return false;
    }
    return true;
}

export fn problem58(ratio: f64) f64 {
    if (!(ratio >= 0.1 and ratio <= 0.6)) return -1.0;
    var side: i64 = 3;
    var prime_count: i64 = 3;
    while (@as(f64, @floatFromInt(prime_count)) / @as(f64, @floatFromInt(2 * side - 1)) >= ratio) {
        const square = side * side;
        const step = side + 1;
        if (is_prime(square + step)) prime_count += 1;
        if (is_prime(square + 2 * step)) prime_count += 1;
        if (is_prime(square + 3 * step)) prime_count += 1;
        side += 2;
    }
    return @floatFromInt(side);
}
