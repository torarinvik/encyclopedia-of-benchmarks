package euler_problem_7

import "core:c"

SIEVE_LIMIT :: 1_000_000
MAX_ORDINAL :: i64(10_001)
MAX_VALID_INPUT_LENGTH :: c.size_t(1)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(2)

@(export)
euler_problem_7 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < MAX_VALID_INPUT_LENGTH || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if length != MAX_VALID_INPUT_LENGTH do return -1
	ordinal := input[0]
	if ordinal < 1 || ordinal > MAX_ORDINAL do return -1

	var composite: [SIEVE_LIMIT]bool
	count := i64(0)
	for candidate := 2; candidate < SIEVE_LIMIT; candidate += 1 {
		if !composite[candidate] {
			count += 1
			if count == ordinal do return i64(candidate)
			for multiple := candidate * 2; multiple < SIEVE_LIMIT; multiple += candidate {
				composite[multiple] = true
			}
		}
	}
	return -1
}
