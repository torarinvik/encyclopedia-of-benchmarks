/// Compute Fibonacci numbers by portable 64-bit fast doubling.
export fn fibonacci_fast(input: i64) i64 {
    if (input < 0 or input > 92) return -1;
    const n: u64 = @intCast(input);
    var bit: u64 = 1;
    while (bit <= n / 2) : (bit <<= 1) {}
    var current: u64 = 0;
    var next: u64 = 1;
    while (bit != 0) : (bit >>= 1) {
        const even = current * (2 * next - current);
        const odd = current * current + next * next;
        if ((n & bit) != 0) {
            current = odd;
            next = even + odd;
        } else {
            current = even;
            next = odd;
        }
    }
    return @intCast(current);
}
