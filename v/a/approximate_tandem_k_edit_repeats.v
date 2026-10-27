module approximate_tandem_k_edit_repeats

const max_text = 12
const max_input = 14
const max_output = 1592

fn edit_distance(input []i64, a int, a_length int, b int, b_length int) int {
	mut row := []int{len: max_text + 1, init: 0}
	for j in 0 .. b_length + 1 { row[j] = j }
	for i in 1 .. a_length + 1 {
		mut diagonal := row[0]
		row[0] = i
		for j in 1 .. b_length + 1 {
			above := row[j]
			deletion := above + 1
			insertion := row[j - 1] + 1
			mut substitution := diagonal
			if input[2 + a + i - 1] != input[2 + b + j - 1] { substitution++ }
			row[j] = min(min(deletion, insertion), substitution)
			diagonal = above
		}
	}
	return row[b_length]
}

fn minimum_edit_cost(input []i64, start int, factor_length int) int {
	mut best := 1000
	mut piece_starts := []int{len: max_text, init: 0}
	mut piece_lengths := []int{len: max_text, init: 0}
	for prefix in 0 .. factor_length + 1 {
		for suffix in 0 .. factor_length - prefix + 1 {
			middle := factor_length - prefix - suffix
			if middle < 2 { continue }
			end_mask := 1 << (middle - 1)
			for mask in 1 .. end_mask {
				mut segments := 0
				mut previous := 0
				for cut in 1 .. middle {
					if (mask & (1 << (cut - 1))) != 0 {
						piece_starts[segments] = start + prefix + previous
						piece_lengths[segments] = cut - previous
						segments++
						previous = cut
					}
				}
				piece_starts[segments] = start + prefix + previous
				piece_lengths[segments] = middle - previous
				segments++
				mut left := 1000
				for fragment in 0 .. piece_lengths[0] + 1 {
					cost := edit_distance(input, start, prefix,
						piece_starts[0] + piece_lengths[0] - fragment, fragment)
					if cost < left { left = cost }
				}
				last := segments - 1
				mut right := 1000
				for fragment in 0 .. piece_lengths[last] + 1 {
					cost := edit_distance(input, piece_starts[last], fragment,
						start + factor_length - suffix, suffix)
					if cost < right { right = cost }
				}
				mut internal := 0
				for i in 0 .. last {
					internal += edit_distance(input, piece_starts[i], piece_lengths[i],
						piece_starts[i + 1], piece_lengths[i + 1])
				}
				total := left + internal + right
				if total < best { best = total }
			}
		}
	}
	return best
}

fn count_records(input []i64, n int, budget int) int {
	mut count := 0
	for start in 0 .. n {
		for factor_length in 2 .. n - start + 1 {
			if minimum_edit_cost(input, start, factor_length) <= budget { count++ }
		}
	}
	return count
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'approximate_tandem_k_edit_repeats']
pub fn approximate_tandem_k_edit_repeats(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n0 := input[0]
		budget0 := input[1]
		if n0 < 2 || n0 > max_text || budget0 < 0 || budget0 > 4 || length != usize(n0 + 2) { return -1 }
		n := int(n0)
		budget := int(budget0)
		mut values := []i64{len: n + 2, init: 0}
		for i in 0 .. n + 2 { values[i] = input[i] }
		for i in 0 .. n { if values[2 + i] < 0 || values[2 + i] > 3 { return -1 } }
		count := count_records(values, n, budget)
		bytes := 8 * (1 + 3 * count)
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		store_i64_le(mut output, 0, i64(count))
		mut record := 0
		for start in 0 .. n {
			for factor_length in 2 .. n - start + 1 {
				cost := minimum_edit_cost(values, start, factor_length)
				if cost <= budget {
					offset := 8 * (1 + 3 * record)
					store_i64_le(mut output, offset, i64(start))
					store_i64_le(mut output, offset + 8, i64(factor_length))
					store_i64_le(mut output, offset + 16, i64(cost))
					record++
				}
			}
		}
		return i64(bytes)
	}
}
