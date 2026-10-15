fn highestCommonFactorImpl(x: u64, y: u64) u64 {
    if (x == 0) return y;
    if (y == 0) return x;
    if (x == y) return x;
    if (y > x) return highestCommonFactorImpl(y - x, x);
    return highestCommonFactorImpl(x - y, y);
}

export fn highest_common_factor(x: u64, y: u64) i64 {
    return @intCast(highestCommonFactorImpl(x, y));
}
