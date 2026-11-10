/// Count low-order zero bits.
export fn binary_count_trailing_zeros(n: i64) i64 {
    if (n <= 0) return if (n < 0) -1 else 0;
    return @ctz(n);
}
