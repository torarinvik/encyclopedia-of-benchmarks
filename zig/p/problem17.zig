export fn problem17(limit: i64) i64 {
    if (limit < 0 or limit > 1000) return -1;
    const ones = [_]i64{ 0, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8 };
    const tens = [_]i64{ 0, 0, 6, 6, 5, 5, 5, 7, 6, 6 };
    var total: i64 = 0;
    var value: i64 = 1;
    while (value <= limit) : (value += 1) {
        if (value == 1000) {
            total += ones[1] + 8;
            continue;
        }
        var remainder = value;
        if (value >= 100) {
            total += ones[@intCast(@divTrunc(value, 100))] + 7;
            remainder = @mod(value, 100);
            if (remainder != 0) total += 3;
        }
        if (remainder < 20) {
            total += ones[@intCast(remainder)];
        } else {
            total += tens[@intCast(@divTrunc(remainder, 10))] + ones[@intCast(@mod(remainder, 10))];
        }
    }
    return total;
}
