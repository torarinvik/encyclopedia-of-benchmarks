/// Remainder check from the pinned JavaScript and TypeScript sources.
export fn is_divisible(dividend: u64, divisor: u64) i64 {
    if (dividend > 1_000_000_000 or divisor == 0 or divisor > 1_000_000_000) return -1;
    return if (dividend % divisor == 0) 1 else 0;
}
