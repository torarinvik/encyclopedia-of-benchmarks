fn problem27IsPrime(value: i64) bool {
    if (value < 2) return false;
    if (@rem(value, 2) == 0) return value == 2;
    if (@rem(value, 3) == 0) return value == 3;
    var factor: i64 = 5;
    while (factor <= @divTrunc(value, factor)) : (factor += 6) {
        if (@rem(value, factor) == 0 or @rem(value, factor + 2) == 0) return false;
    }
    return true;
}

export fn problem27(limit: i64) i64 {
    if (limit < 1 or limit > 1000) return -1;
    var best_length: i64 = 0;
    var best_a: i64 = 0;
    var best_b: i64 = 0;
    var a: i64 = 1 - limit;
    while (a < limit) : (a += 1) {
        var b: i64 = 2;
        while (b < limit) : (b += 1) {
            if (!problem27IsPrime(b)) continue;
            var n: i64 = 0;
            while (problem27IsPrime(n * n + a * n + b)) : (n += 1) {}
            if (n > best_length) {
                best_length = n;
                best_a = a;
                best_b = b;
            }
        }
    }
    return best_a * best_b;
}
