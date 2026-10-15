package binary_multiplication

// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
@(export)
binary_multiplication :: proc "c" (a, b: u64) -> i64 {
    multiplicand := a
    multiplier := b
    result: u64 = 0
    for multiplier > 0 {
        if (multiplier & 1) != 0 {
            result += multiplicand
        }
        multiplicand += multiplicand
        multiplier >>= 1
    }
    return i64(result)
}
