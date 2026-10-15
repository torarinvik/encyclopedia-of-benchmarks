package fibonacci_matrix

@(export)
fibonacci_matrix :: proc "c" (index: i64) -> i64 {
	if index < 0 || index > 92 do return -1
	if index == 0 do return 0
	r00: i64 = 1; r01: i64 = 0; r10: i64 = 0; r11: i64 = 1
	b00: i64 = 1; b01: i64 = 1; b10: i64 = 1; b11: i64 = 0
	exponent := index - 1
	for exponent > 0 {
		if exponent % 2 == 1 {
			n00 := r00 * b00 + r01 * b10
			n01 := r00 * b01 + r01 * b11
			n10 := r10 * b00 + r11 * b10
			n11 := r10 * b01 + r11 * b11
			r00 = n00; r01 = n01; r10 = n10; r11 = n11
			exponent -= 1
		} else {
			n00 := b00 * b00 + b01 * b10
			n01 := b00 * b01 + b01 * b11
			n10 := b10 * b00 + b11 * b10
			n11 := b10 * b01 + b11 * b11
			b00 = n00; b01 = n01; b10 = n10; b11 = n11
			exponent /= 2
		}
	}
	return r00
}

main :: proc() {}
