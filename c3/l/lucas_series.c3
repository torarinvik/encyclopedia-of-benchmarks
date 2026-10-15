module lucas_series;
fn long lucas_series(long n) @export("lucas_series") {
    if (n < 0 || n > 90) return -1;
    if (n == 0) return 2;
    long previous = 2;
    long current = 1;
    for (long i = 2; i <= n; i++) { long next = previous + current; previous = current; current = next; }
    return current;
}
