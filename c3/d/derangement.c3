module derangement;

// Return the source-compatible derangement count for n in 0..=20.
fn long derangement(long n) @export("derangement")
{
    if (n < 0 || n > 20) return -1;
    if (n < 2) return 0;
    if (n == 2) return 1;

    long previous = 1;
    long previous_previous = 0;
    for (long i = 3; i <= n; i++) {
        long current = (i - 1) * (previous + previous_previous);
        previous_previous = previous;
        previous = current;
    }
    return previous;
}
