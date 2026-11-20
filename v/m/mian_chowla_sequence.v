module mian_chowla_sequence

const max_n = i64(30)
const max_parseable_length = 2

@[export: 'mian_chowla_sequence']
pub fn mian_chowla_sequence(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		requested := input[0]
		if length != 1 || requested < 1 || requested > max_n { return -1 }

		mut terms := [30]i64{}
		mut used_sums := [465]i64{}
		mut term_count := 1
		mut sum_count := 1
		terms[0] = 1
		used_sums[0] = 2

		for term_count < int(requested) {
			mut candidate := terms[term_count - 1] + 1
			for {
				mut valid := true
				for term := 0; term < term_count && valid; term++ {
					sum := candidate + terms[term]
					for old := 0; old < sum_count; old++ {
						if used_sums[old] == sum { valid = false; break }
					}
				}
				if valid {
					doubled := 2 * candidate
					for old := 0; old < sum_count; old++ {
						if used_sums[old] == doubled { valid = false; break }
					}
				}
				if valid { break }
				candidate++
			}

			for term := 0; term < term_count; term++ {
				used_sums[sum_count] = candidate + terms[term]
				sum_count++
			}
			used_sums[sum_count] = 2 * candidate
			sum_count++
			terms[term_count] = candidate
			term_count++
		}
		return terms[int(requested) - 1]
	}
}
