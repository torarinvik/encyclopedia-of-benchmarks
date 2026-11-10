/// Test whether a signed value is an exact integer cube.
export fn perfect_cube(value: i64) i64 {
    if (value < -1_000_000_000_000 or value > 1_000_000_000_000) return -1;
    const target: u64 = @abs(value);
    if (target < 2) return 1;
    const root_limit: u64 = if (target <= 1000) 10 else if (target <= 1000000) 100 else if (target <= 1000000000) 1000 else 10000;
    var low: u64 = 1;
    var high = @min(target / 2, root_limit);
    while (low <= high) {
        const middle = (low + high) >> 1;
        const cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) {
            if (middle == high) return 0;
            low = middle + 1;
        } else {
            if (middle == low) return 0;
            high = middle - 1;
        }
    }
    return 0;
}
