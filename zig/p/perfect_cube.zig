/// Test whether a signed value is an exact integer cube.
export fn perfect_cube(value: i64) i64 {
    if (value < -1_000_000_000_000 or value > 1_000_000_000_000) return -1;
    const target: i64 = if (value < 0) -value else value;
    var low: i64 = 0;
    var high: i64 = 10_000;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        const cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) low = middle + 1 else high = middle - 1;
    }
    return 0;
}
