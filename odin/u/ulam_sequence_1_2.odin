package ulam_sequence_1_2

import "core:c"

MAX_N :: 14
MAX_CANDIDATE :: 64
MAX_PARSEABLE_LENGTH :: 2

@(export)
ulam_sequence_1_2 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	requested := input[0]
	if length != 1 || requested < 1 || requested > i64(MAX_N) do return -1

	terms: [14]i64 = {}
	representations: [75]i64 = {}
	terms[0] = 1
	terms[1] = 2
	representations[3] = 1
	term_count := 2

	for term_count < int(requested) {
		candidate := terms[term_count - 1] + 1
		for candidate <= i64(MAX_CANDIDATE) && representations[int(candidate)] != 1 {
			candidate += 1
		}
		if candidate > i64(MAX_CANDIDATE) do return -1
		for old := 0; old < term_count; old += 1 {
			sum := int(candidate + terms[old])
			if representations[sum] < 2 do representations[sum] += 1
		}
		terms[term_count] = candidate
		term_count += 1
	}
	return terms[int(requested) - 1]
}
