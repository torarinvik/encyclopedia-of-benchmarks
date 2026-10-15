/// Count low-order zero bits by shifting away factors of two.
export fn binary_count_trailing_zeros(input: i64) i64 {
    if (input < 0) return -1;
    var n = input;
    var count: i64 = 0;
    while (n > 0 and (n & 1) == 0) {
        n >>= 1;
        count += 1;
    }
    return count;
}
