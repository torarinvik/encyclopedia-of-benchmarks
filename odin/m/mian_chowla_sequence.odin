package mian_chowla_sequence

import "core:c"

MAX_N :: 30
MAX_PARSEABLE_LENGTH :: 2

@(export)
mian_chowla_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	requested := input[0]
	if length != 1 || requested < 1 || requested > i64(MAX_N) do return -1

	terms: [30]i64 = {}
	used_sums: [465]i64 = {}
	term_count := 1
	sum_count := 1
	terms[0] = 1
	used_sums[0] = 2

	for term_count < int(requested) {
		candidate := terms[term_count - 1] + 1
		for {
			valid := true
			for term := 0; term < term_count && valid; term += 1 {
				sum := candidate + terms[term]
				for old := 0; old < sum_count; old += 1 {
					if used_sums[old] == sum {
						valid = false
						break
					}
				}
			}
			if valid {
				doubled := 2 * candidate
				for old := 0; old < sum_count; old += 1 {
					if used_sums[old] == doubled {
						valid = false
						break
					}
				}
			}
			if valid do break
			candidate += 1
		}

		for term := 0; term < term_count; term += 1 {
			used_sums[sum_count] = candidate + terms[term]
			sum_count += 1
		}
		used_sums[sum_count] = 2 * candidate
		sum_count += 1
		terms[term_count] = candidate
		term_count += 1
	}
	return terms[int(requested) - 1]
}
