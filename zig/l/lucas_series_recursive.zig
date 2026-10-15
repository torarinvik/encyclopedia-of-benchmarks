fn solve(n: i64) i64 {
    if (n == 0) return 2;
    if (n == 1) return 1;
    return solve(n - 1) + solve(n - 2);
}
export fn lucas_series_recursive(n: i64) i64 {
    if (n < 0 or n > 25) return -1;
    return solve(n);
}
