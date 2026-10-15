/// Return the source-compatible derangement count for n in 0..=20.
export fn derangement(n: i64) i64 {
    if (n < 0 or n > 20) return -1;
    if (n < 2) return 0;
    if (n == 2) return 1;

    var previous: i64 = 1;
    var previous_previous: i64 = 0;
    var i: i64 = 3;
    while (i <= n) : (i += 1) {
        const current = (i - 1) * (previous + previous_previous);
        previous_previous = previous;
        previous = current;
    }
    return previous;
}
