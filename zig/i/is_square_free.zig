/// Return whether positive n has no repeated prime factor.
export fn is_square_free(n: i64) i64 {
    if (n < 1 or n > 1000000) return -1;
    var remaining = n;
    var factor: i64 = 2;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
        if (@rem(remaining, factor) == 0) {
            remaining = @divTrunc(remaining, factor);
            if (@rem(remaining, factor) == 0) return 0;
        }
    }
    return 1;
}
