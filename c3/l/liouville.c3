module liouville;

// Go's distinct-factor Liouville variant: (-1) raised to omega(n).
fn long liouville(long input) @export("liouville")
{
    if (input < 1 || input > 2147483647) return -2;
    ulong remaining = (ulong)input;
    long sign = 1;
    ulong factor = 2;
    while (factor <= remaining / factor) {
        if (remaining % factor == 0) {
            sign = -sign;
            while (remaining % factor == 0) {
                remaining /= factor;
            }
        }
        if (factor == 2) factor = 3; else factor += 2;
    }
    if (remaining > 1) sign = -sign;
    return sign;
}
