module lucas_series_recursive;
fn long solve(long n) {
    if (n == 0) return 2;
    if (n == 1) return 1;
    return solve(n - 1) + solve(n - 2);
}
fn long lucas_series_recursive(long n) @export("lucas_series_recursive") {
    if (n < 0 || n > 25) return -1;
    return solve(n);
}
