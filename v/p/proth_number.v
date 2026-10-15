module proth_number

// Preserve the source's factor-of-two reduction for Proth membership.
@[export: 'is_proth_number']
pub fn is_proth_number(input i64) i64 {
	if input <= 0 { return -1 }
	if input == 1 { return 0 }

	mut remainder := input - 1
	mut exponent := 0
	for remainder % 2 == 0 {
		exponent++
		remainder /= 2
	}
	return if remainder < (i64(1) << exponent) { 1 } else { 0 }
}
