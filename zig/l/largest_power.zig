/// Legendre's formula for the exponent of prime p in n!.
fn isPrime(value: u64) bool {
    if (value < 2) return false;
    var divisor: u64 = 2;
    while (divisor <= value / divisor) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

export fn largest_power(n: u64, p: u64) i64 {
    if (n > 4294967295 or p > 65535 or !isPrime(p)) return -1;
    var quotient = n;
    var total: i64 = 0;
    while (quotient != 0) {
        quotient /= p;
        total += @intCast(quotient);
    }
    return total;
}
