module kasai_algorithm

import core:c

const max_length = 512
const fnv_offset_basis = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn fnv_word(hash u64, value i64) u64 {
	bits := u64(value)
	mut result := hash
	for byte in 0 .. 8 {
		result = (result ^ ((bits >> (8 * byte)) & 255)) * fnv_prime
	}
	return result
}

@[export: 'kasai_algorithm']
pub fn kasai_algorithm(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > i64(max_length) { return -1 }
		n := int(values[0])
		if length != usize(1 + 2 * values[0]) { return -1 }
		for i in 0 .. n {
			if values[1 + i] < 0 || values[1 + i] > 127 { return -1 }
		}

		mut suffixes := [max_length]int{}
		mut rank := [max_length]int{}
		mut seen := [max_length]bool{}
		mut lcp := [max_length]i64{}
		for position in 0 .. n {
			suffix_value := values[1 + n + position]
			if suffix_value < 0 || suffix_value >= i64(n) { return -1 }
			suffix := int(suffix_value)
			if seen[suffix] { return -1 }
			seen[suffix] = true
			suffixes[position] = suffix
			rank[suffix] = position
		}

		if n > 1 {
			for position in 1 .. n {
				left, right := suffixes[position - 1], suffixes[position]
				left_tail_rank := if left + 1 < n { rank[left + 1] } else { -1 }
				right_tail_rank := if right + 1 < n { rank[right + 1] } else { -1 }
				left_byte, right_byte := values[1 + left], values[1 + right]
				if left_byte > right_byte || (left_byte == right_byte && left_tail_rank >= right_tail_rank) { return -1 }
			}
		}

		mut common := 0
		for start in 0 .. n {
			current_rank := rank[start]
			if current_rank == n - 1 { common = 0; continue }
			next_start := suffixes[current_rank + 1]
			for start + common < n && next_start + common < n && values[1 + start + common] == values[1 + next_start + common] {
				common++
			}
			lcp[current_rank] = i64(common)
			if common > 0 { common-- }
		}

		mut hash := fnv_word(fnv_offset_basis, i64(n))
		for i in 0 .. n { hash = fnv_word(hash, lcp[i]) }
		return i64(hash & 0x7fffffffffffffff)
	}
}
