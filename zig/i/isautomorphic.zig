/// Preserve the Go source's direct square-and-last-digit loop.
export fn isautomorphic(n: i64) i64 {
    const max_safe: i64 = 3_037_000_499;
    if (n < -max_safe or n > max_safe) return -1;
    if (n < 0) return 0;

    var square = n * n;
    var remaining = n;
    while (remaining > 0) {
        if (remaining % 10 != square % 10) return 0;
        remaining = @divTrunc(remaining, 10);
        square = @divTrunc(square, 10);
    }
    return 1;
}
