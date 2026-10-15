/// Check whether a signed 32-bit integer is a perfect square.
export fn perfect_square_checker(n: i64) i64 {
    if (n < -2147483648 or n > 2147483647) return -1;
    if (n < 0) return 0;

    var low: i64 = 0;
    var high: i64 = 46340;
    while (low <= high) {
        const mid = low + @divTrunc(high - low, 2);
        const square = mid * mid;
        if (square == n) return 1;
        if (square < n) low = mid + 1 else high = mid - 1;
    }
    return 0;
}
