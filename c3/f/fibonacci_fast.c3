module fibonacci_fast;

// Compute Fibonacci numbers by portable 64-bit fast doubling.
fn long fibonacci_fast(long input) @export("fibonacci_fast") {
    if (input < 0 || input > 92) return -1;
    ulong n = (ulong)input;
    ulong bit = 1;
    while (bit <= n / 2) bit = bit << 1;
    ulong current = 0;
    ulong next = 1;
    while (bit != 0) {
        ulong even = current * (2 * next - current);
        ulong odd = current * current + next * next;
        if ((n & bit) != 0) {
            current = odd;
            next = even + odd;
        } else {
            current = even;
            next = odd;
        }
        bit = bit >> 1;
    }
    return (long)current;
}
