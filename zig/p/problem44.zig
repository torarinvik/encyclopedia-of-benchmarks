fn is_pentagonal(value: i64) bool {
    if (value < 1) return false;
    const discriminant = 24 * value + 1;
    const root: i64 = @intFromFloat(@sqrt(@as(f64, @floatFromInt(discriminant))));
    return root * root == discriminant and @mod(root + 1, 6) == 0;
}

export fn problem44(limit: i64) i64 {
    if (limit < 1 or limit > 5000) return -1;
    var i: i64 = 1;
    while (i < limit) : (i += 1) {
        const first = i * (3 * i - 1) / 2;
        var j = i;
        while (j < limit) : (j += 1) {
            const second = j * (3 * j - 1) / 2;
            const difference = second - first;
            if (is_pentagonal(first + second) and is_pentagonal(difference)) return difference;
        }
    }
    return -1;
}
