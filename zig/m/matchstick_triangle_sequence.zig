export fn matchstick_triangle_sequence(n: i64) i64 {
    if (n < 0 or n > 1000000) return -1;
    return @divTrunc(n * (n + 2) * (2 * n + 1), 8);
}
