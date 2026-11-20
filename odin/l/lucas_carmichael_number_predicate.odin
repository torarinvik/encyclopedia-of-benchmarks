package lucas_carmichael_number_predicate

import "core:c"

MAX_VALUE :: i64(1_000_000)

@(export)
lucas_carmichael_number_predicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	value := input[0]
	if value < 1 || value > MAX_VALUE do return -1

	remaining := value
	divisor := i64(2)
	composite := false
	for divisor <= remaining / divisor {
		if remaining % divisor == 0 {
			composite = true
			exponent := 0
			for remaining % divisor == 0 {
				remaining /= divisor
				exponent += 1
			}
			if exponent != 1 || (value + 1) % (divisor + 1) != 0 do return 0
		}
		divisor += 1
	}
	if remaining > 1 {
		if !composite || (value + 1) % (remaining + 1) != 0 do return 0
	}
	if composite do return 1
	return 0
}
