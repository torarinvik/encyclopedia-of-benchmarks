package proth_number

// Preserve the source's factor-of-two reduction for Proth membership.
@(export)
is_proth_number :: proc "c" (input: i64) -> i64 {
	if input <= 0 do return -1
	if input == 1 do return 0

	remainder := input - 1
	exponent: u32 = 0
	for remainder % 2 == 0 {
		exponent += 1
		remainder /= 2
	}
	return if remainder < (i64(1) << exponent) { 1 } else { 0 }
}
