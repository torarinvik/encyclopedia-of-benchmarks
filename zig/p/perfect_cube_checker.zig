/// Check whether a signed 32-bit integer is a perfect cube.
export fn perfect_cube_checker(n: i64) i64 {
    if (n < -2147483648 or n > 2147483647) return -1;

    const magnitude = if (n < 0) -n else n;
    var low: i64 = 0;
    var high: i64 = 1290;
    while (low <= high) {
        const mid = low + @divTrunc(high - low, 2);
        const cube = mid * mid * mid;
        if (cube == magnitude) return 1;
        if (cube < magnitude) low = mid + 1 else high = mid - 1;
    }
    return 0;
}
