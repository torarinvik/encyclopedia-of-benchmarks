module problem52;

fn void digit_counts(long value, int* counts) {
    for (usz i = 0; i < 10; ++i) counts[i] = 0;
    while (value > 0) { counts[(usz)(value % 10)]++; value /= 10; }
}
fn bool same_digits(long left, long right) {
    int[10] a, b; digit_counts(left, &a[0]); digit_counts(right, &b[0]);
    for (usz i = 0; i < 10; ++i) if (a[i] != b[i]) return false;
    return true;
}
fn long problem52(long unused) @export("problem52") {
    if (unused != 0) return -1;
    for (long value = 1;; ++value) {
        bool matches = true;
        for (long multiplier = 2; multiplier <= 6 && matches; ++multiplier)
            matches = same_digits(value, multiplier * value);
        if (matches) return value;
    }
}
