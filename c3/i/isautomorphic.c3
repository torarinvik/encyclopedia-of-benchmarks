module isautomorphic;

// Preserve the Go source's direct square-and-last-digit loop.
fn long isautomorphic(long n) @export("isautomorphic") {
    long max_safe = 3037000499;
    if (n < -max_safe || n > max_safe) return -1;
    if (n < 0) return 0;

    long square = n * n;
    long remaining = n;
    while (remaining > 0) {
        if (remaining % 10 != square % 10) return 0;
        remaining /= 10;
        square /= 10;
    }
    return 1;
}
