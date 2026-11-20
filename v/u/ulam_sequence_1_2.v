module ulam_sequence_1_2

const max_n = i64(14)
const max_candidate = i64(64)
const max_parseable_length = 2

@[export: 'ulam_sequence_1_2']
pub fn ulam_sequence_1_2(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		requested := input[0]
		if length != 1 || requested < 1 || requested > max_n { return -1 }

		mut terms := [14]i64{}
		mut representations := [75]i64{}
		terms[0] = 1
		terms[1] = 2
		representations[3] = 1
		mut term_count := 2

		for term_count < int(requested) {
			mut candidate := terms[term_count - 1] + 1
			for candidate <= max_candidate && representations[int(candidate)] != 1 {
				candidate++
			}
			if candidate > max_candidate { return -1 }
			for old := 0; old < term_count; old++ {
				sum := int(candidate + terms[old])
				if representations[sum] < 2 { representations[sum]++ }
			}
			terms[term_count] = candidate
			term_count++
		}
		return terms[int(requested) - 1]
	}
}
