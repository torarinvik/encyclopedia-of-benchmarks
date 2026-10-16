module problem38;

fn bool is_9_pandigital(long value) {
    if (value < 100000000 || value > 999999999) return false;
    uint mask = 0;
    while (value > 0) {
        uint digit = (uint)(value % 10);
        if (digit == 0 || (mask & (1u << digit)) != 0) return false;
        mask |= 1u << digit;
        value /= 10;
    }
    return mask == 0x3fe;
}

fn long problem38(long unused) @export("problem38") {
    if (unused != 0) return -1;
    for (long base = 9999; base > 4999; base--) {
        long candidate = 100002 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    for (long base = 333; base > 99; base--) {
        long candidate = 1002003 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    return -1;
}
