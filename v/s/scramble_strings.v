const max_length = 8
const max_parseable_input_length = 2 * max_length + 3
const memo_size = 9 * 9 * 9

fn scramble_rec(values &i64, base1 int, base2 int, start1 int, start2 int, span int, memo &i64) i64 {
	unsafe {
		slot := (start1 * 9 + start2) * 9 + span
		if memo[slot] >= 0 { return memo[slot] }

		mut same := true
		for offset in 0 .. span {
			if values[base1 + start1 + offset] != values[base2 + start2 + offset] {
				same = false
				break
			}
		}
		if same {
			memo[slot] = 1
			return 1
		}

		mut counts := [26]i64{}
		for offset in 0 .. span {
			counts[int(values[base1 + start1 + offset] - 97)]++
			counts[int(values[base2 + start2 + offset] - 97)]--
		}
		for count in counts {
			if count != 0 {
				memo[slot] = 0
				return 0
			}
		}

		for split in 1 .. span {
			if scramble_rec(values, base1, base2, start1, start2, split, memo) != 0 &&
				scramble_rec(values, base1, base2, start1 + split, start2 + split, span - split, memo) != 0 {
				memo[slot] = 1
				return 1
			}
			if scramble_rec(values, base1, base2, start1, start2 + span - split, split, memo) != 0 &&
				scramble_rec(values, base1, base2, start1 + split, start2, span - split, memo) != 0 {
				memo[slot] = 1
				return 1
			}
		}
		memo[slot] = 0
		return 0
	}
}

@[export: 'scramble_strings']
pub fn scramble_strings(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_parseable_input_length { return -1 }
	unsafe {
		n_value := values[0]
		if n_value < 0 || n_value > max_length { return -1 }
		n := int(n_value)
		if length != usize(2 * n + 1) { return -1 }
		for index in 1 .. int(length) {
			if values[index] < 97 || values[index] > 122 { return -1 }
		}

		mut memo := [memo_size]i64{}
		for index in 0 .. memo_size { memo[index] = -1 }
		return scramble_rec(values, 1, 1 + n, 0, 0, n, &memo[0])
	}
}
