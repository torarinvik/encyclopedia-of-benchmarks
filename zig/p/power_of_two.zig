/// Return 1 when n is a positive power of two, otherwise 0.
export fn power_of_two(n: i64) i64 {
    if (n <= 0) return 0;
    return if ((n & (n - 1)) == 0) 1 else 0;
}
