package fibonacci_fast

@(export)
fibonacci_fast :: proc "c" (input: i64) -> i64 {
    if input < 0 || input > 92 do return -1
    n := u64(input)
    bit := u64(1)
    for bit <= n / 2 { bit <<= 1 }
    current, next := u64(0), u64(1)
    for bit != 0 {
        even := current * (2 * next - current)
        odd := current * current + next * next
        if (n & bit) != 0 {
            current = odd
            next = even + odd
        } else {
            current = even
            next = odd
        }
        bit >>= 1
    }
    return i64(current)
}
