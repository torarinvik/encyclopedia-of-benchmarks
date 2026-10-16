module multiply_digit

// Multiply two bounded signed operands; the bounds guarantee an i64 result.
@[export: 'multiply_digit']
pub fn multiply_digit(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 2 { return i64(-9223372036854775807) - 1 }
	first := unsafe { values[0] }
	second := unsafe { values[1] }
	if first < -1000000000 || first > 1000000000 ||
		second < -1000000000 || second > 1000000000 {
		return i64(-9223372036854775807) - 1
	}
	return first * second
}
