export fn problem9(total: i64) i64 {
    if (total < 3 or total > 1000) return -1;
    var a: i64 = 1;
    while (a <= @divTrunc(total, 3)) : (a += 1) {
        var b = a + 1;
        while (2 * b < total - a) : (b += 1) {
            const c = total - a - b;
            if (a * a + b * b == c * c) return a * b * c;
        }
    }
    return -1;
}
