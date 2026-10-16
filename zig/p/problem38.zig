fn is9Pandigital(value: i64) bool {
    if (value < 100000000 or value > 999999999) return false;
    var mask: u16 = 0;
    var remaining = value;
    while (remaining > 0) {
        const digit: u16 = @intCast(@rem(remaining, 10));
        if (digit == 0 or (mask & (@as(u16, 1) << @intCast(digit))) != 0) return false;
        mask |= @as(u16, 1) << @intCast(digit);
        remaining = @divTrunc(remaining, 10);
    }
    return mask == 0x3fe;
}

export fn problem38(unused: i64) i64 {
    if (unused != 0) return -1;
    var base: i64 = 9999;
    while (base > 4999) : (base -= 1) {
        const candidate = 100002 * base;
        if (is9Pandigital(candidate)) return candidate;
    }
    base = 333;
    while (base > 99) : (base -= 1) {
        const candidate = 1002003 * base;
        if (is9Pandigital(candidate)) return candidate;
    }
    return -1;
}
