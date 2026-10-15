/// Test whether n is a positive Dudeney number: cube root equals digit sum.
export fn dudeney_number(number: i64) i64 {
    if (number <= 0 or number > 2147483647) return -1;
    var low: i64 = 1;
    var high: i64 = 1290;
    var root: i64 = 0;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        const cube = middle * middle * middle;
        if (cube == number) { root = middle; break; }
        if (cube < number) low = middle + 1 else high = middle - 1;
    }
    if (root == 0) return 0;
    var remaining = number;
    var sum: i64 = 0;
    while (remaining > 0) {
        sum += @mod(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return if (sum == root) 1 else 0;
}
