fn gcd(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

export fn problem5(limit: i64) i64 {
    if (limit < 1 or limit > 20) return -1;
    var result: i64 = 1;
    var value: i64 = 2;
    while (value <= limit) : (value += 1) {
        result = @divTrunc(result, gcd(result, value)) * value;
    }
    return result;
}
