/// Match the pinned source: odd exponents return F(exponent + 2) - 1.
export fn problem301(exponent: i64) i64 {
    if (exponent < 0 or exponent > 30) return -1;
    var previous: i64 = 0;
    var current: i64 = 1;
    var index: i64 = 0;
    while (index < exponent + 2) : (index += 1) {
        const next = previous + current;
        previous = current;
        current = next;
    }
    return previous - @mod(exponent, 2);
}
