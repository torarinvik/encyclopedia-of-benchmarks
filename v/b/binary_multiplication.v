module binary_multiplication

// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
@[export: 'binary_multiplication']
pub fn binary_multiplication(a u64, b u64) i64 {
    mut multiplicand := a
    mut multiplier := b
    mut accumulated := u64(0)
    for multiplier > 0 {
        if (multiplier & 1) != 0 {
            accumulated += multiplicand
        }
        multiplicand += multiplicand
        multiplier >>= 1
    }
    return i64(accumulated)
}
