module problem53;
fn long problem53(long unused) @export("problem53") {
    if (unused != 0) return -1;
    long total = 0;
    for (long n = 1; n <= 100; ++n) {
        long coefficient = 1;
        for (long r = 1; r <= n / 2; ++r) {
            coefficient = coefficient * (n - r + 1) / r;
            if (coefficient > 1000000) { total += n - 2 * r + 1; break; }
        }
    }
    return total;
}
