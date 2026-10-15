module bitwise_addition

// Add nonnegative integers with XOR and shifted AND carry propagation.
@[export: 'bitwise_addition']
pub fn bitwise_addition(first u64, second u64) i64 {
	mut left := first
	mut carry_bits := second
	for carry_bits != 0 {
		carry := left & carry_bits
		left ^= carry_bits
		carry_bits = carry << 1
	}
	return i64(left)
}
