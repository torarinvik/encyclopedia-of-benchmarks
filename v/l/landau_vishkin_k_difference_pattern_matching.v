const max_pattern = 16
const max_text = 32
const max_errors = 2
const max_valid_input = 3 + max_pattern + max_text
const max_parseable_input = max_valid_input + 1
const diagonals = max_text + max_errors + 3
const costs = max_errors + 2

@[export: 'landau_vishkin_k_difference_pattern_matching']
pub fn landau_vishkin_k_difference_pattern_matching(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input {
			return -1
		}
		raw_m := input[0]
		raw_n := input[1]
		raw_k := input[2]
		if raw_m < 1 || raw_m > max_pattern || raw_n < 0 || raw_n > max_text ||
			raw_k < 0 || raw_k > max_errors || raw_k >= raw_m {
			return -1
		}
		m, n, k := int(raw_m), int(raw_n), int(raw_k)
		if length != usize(3 + m + n) {
			return -1
		}
		for index in 0 .. m {
			symbol := input[3 + index]
			if symbol < 0 || symbol > 3 {
				return -1
			}
		}
		for index in 0 .. n {
			symbol := input[3 + m + index]
			if symbol < 0 || symbol > 3 {
				return -1
			}
		}
		if output == nil || capacity < usize(n) {
			return -2
		}

		mut frontier := [diagonals][costs]i64{}
		for d in 0 .. diagonals {
			for e in 0 .. costs {
				frontier[d][e] = -1
			}
		}
		for d := -(k + 1); d < 0; d++ {
			magnitude := -d
			base := d + max_errors + 1
			frontier[base][magnitude] = i64(magnitude - 1)
			frontier[base][magnitude - 1] = i64(magnitude - 2)
		}
		mut staged := [max_text]u8{}
		for errors in 0 .. k + 1 {
			for d := -errors; d < n + 1; d++ {
				base := d + max_errors + 1
				mut row := max(frontier[base][errors] + 1,
					max(frontier[base - 1][errors], frontier[base + 1][errors] + 1))
				row = min(row, raw_m)
				for row < raw_m {
					text_index := row + i64(d)
					if text_index < 0 || text_index >= raw_n ||
						input[3 + int(row)] != input[3 + m + int(text_index)] {
						break
					}
					row++
				}
				frontier[base][errors + 1] = row
				if row == raw_m {
					endpoint := i64(d) + raw_m
					if endpoint >= 1 && endpoint <= raw_n {
						staged[int(endpoint - 1)] = 1
					}
				}
			}
		}
		for index in 0 .. n {
			output[index] = staged[index]
		}
		return i64(n)
	}
}
