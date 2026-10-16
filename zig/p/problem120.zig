const MAX_LIMIT: i64 = 1000;

pub export fn problem120(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var total: i64 = 0;
    var a: i64 = 3;
    while (a <= limit) : (a += 1) {
        total += 2 * a * @divTrunc(a - 1, 2);
    }
    return total;
}
