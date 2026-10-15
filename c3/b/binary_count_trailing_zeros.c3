module binary_count_trailing_zeros;

// Count low-order zero bits by shifting away factors of two.
fn long binary_count_trailing_zeros(long n) @export("binary_count_trailing_zeros") {
    if (n < 0) return -1;
    long count = 0;
    while (n > 0 && (n & 1) == 0) {
        n >>= 1;
        count++;
    }
    return count;
}
