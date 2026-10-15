package bitwise_addition

// Add nonnegative integers with XOR and shifted AND carry propagation.
@(export)
bitwise_addition :: proc "c" (first, second: u64) -> i64 {
    left := first
    carry_bits := second
    for carry_bits != 0 {
        carry := left & carry_bits
        left = left ^ carry_bits
        carry_bits = carry << 1
    }
    return i64(left)
}
