fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var factor: i64 = 2;
    while (factor <= @divTrunc(value, factor)) : (factor += 1) {
        if (@mod(value, factor) == 0) return false;
    }
    return true;
}

export fn euclid_numbers_sequence(index: i64) i64 {
    if (index < 0 or index > 15) return -1;
    var product: i64 = 1;
    var primeCount: i64 = 0;
    var candidate: i64 = 2;
    while (primeCount < index + 1) : (candidate += 1) {
        if (isPrime(candidate)) {
            product *= candidate;
            primeCount += 1;
        }
    }
    return product + 1;
}
