fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var factor: i64 = 2;
    while (factor <= @divTrunc(value, factor)) : (factor += 1) {
        if (@mod(value, factor) == 0) return false;
    }
    return true;
}

export fn number_of_primes_by_powers_of10_sequence(index: i64) i64 {
    if (index < 0 or index > 3) return -1;
    if (index == 0) return 0;
    var upper: i64 = 10;
    var exponent: i64 = 1;
    while (exponent < index) : (exponent += 1) upper *= 10;
    var count: i64 = 0;
    var value: i64 = 2;
    while (value < upper) : (value += 1) {
        if (isPrime(value)) count += 1;
    }
    return count;
}
