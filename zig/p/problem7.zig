fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var factor: i64 = 2;
    while (factor <= @divTrunc(value, factor)) : (factor += 1) {
        if (@rem(value, factor) == 0) return false;
    }
    return true;
}

export fn problem7(index: i64) i64 {
    if (index < 1 or index > 10_001) return -1;
    var count: i64 = 0;
    var candidate: i64 = 1;
    while (count < index) {
        candidate += 1;
        if (isPrime(candidate)) count += 1;
    }
    return candidate;
}
