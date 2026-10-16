package primitive_root

import "core:c"

// Search in ascending order for a full period of distinct residues.
@(export)
primitive_root :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 2 || input[0] > 127 do return -1
	modulus := input[0]
	for candidate := i64(1); candidate < modulus; candidate += 1 {
		seen: [127]bool = {}
		power := i64(1)
		is_distinct := true
		for exponent := i64(0); exponent < modulus - 1; exponent += 1 {
			if seen[int(power)] {
				is_distinct = false
				break
			}
			seen[int(power)] = true
			power = (power * candidate) % modulus
		}
		if is_distinct do return candidate
	}
	return 0
}
