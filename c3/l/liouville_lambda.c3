module liouville_lambda;

// Liouville's function: (-1) raised to the number of prime factors with multiplicity.
fn long liouville_lambda(long input) @export("liouville_lambda")
{
    if (input < 1 || input > 2147483647) return -1;
    ulong remaining = (ulong)input;
    long sign = 1;
    ulong factor = 2;
    while (factor <= remaining / factor) {
        while (remaining % factor == 0) {
            remaining /= factor;
            sign = -sign;
        }
        if (factor == 2) factor = 3; else factor += 2;
    }
    if (remaining > 1) sign = -sign;
    return sign;
}
