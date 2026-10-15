const MAX_INDEX: i64 = 9_999;

export fn divisors_count_sequence(index: i64) i64 {
    if (index < 0 or index > MAX_INDEX) return -1;
    const n = index + 1;
    if (n == 1) return 1;
    var count: i64 = 2;
    var k: i64 = 2;
    while (k < n) : (k += 1) {
        if (@mod(n, k) == 0) count += 1;
    }
    return count;
}
