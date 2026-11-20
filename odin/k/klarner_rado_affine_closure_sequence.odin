import "core:c"

MAX_INDEX :: 64
MAX_PARSEABLE_LENGTH :: 2

@(export)
klarner_rado_affine_closure_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	requested := input[0]
	if length != 1 || requested < 1 || requested > i64(MAX_INDEX) do return -1

	terms: [64]i64 = {}
	terms[0] = 1
	count := 1
	twice := 0
	thrice_plus_two := 0
	sixfold_plus_three := 0
	for count < int(requested) {
		by_two := 2 * terms[twice]
		by_three := 3 * terms[thrice_plus_two] + 2
		by_six := 6 * terms[sixfold_plus_three] + 3
		next := by_two
		if by_three < next do next = by_three
		if by_six < next do next = by_six
		terms[count] = next
		count += 1
		if by_two == next do twice += 1
		if by_three == next do thrice_plus_two += 1
		if by_six == next do sixfold_plus_three += 1
	}
	return terms[int(requested) - 1]
}
