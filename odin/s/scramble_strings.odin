package scramble_strings

import "core:c"

MAX_LENGTH :: 8
MAX_PARSEABLE_INPUT_LENGTH :: 2 * MAX_LENGTH + 3
MEMO_SIZE :: 9 * 9 * 9

scramble_rec :: proc(values: [^]i64, base1, base2, start1, start2, span: int, memo: [^]i64) -> i64 {
	slot := (start1 * 9 + start2) * 9 + span
	if memo[slot] >= 0 do return memo[slot]

	same := true
	for offset in 0..<span {
		if values[base1 + start1 + offset] != values[base2 + start2 + offset] {
			same = false
			break
		}
	}
	if same {
		memo[slot] = 1
		return 1
	}

	counts: [26]i64 = {}
	for offset in 0..<span {
		counts[int(values[base1 + start1 + offset] - 97)] += 1
		counts[int(values[base2 + start2 + offset] - 97)] -= 1
	}
	for count in counts {
		if count != 0 {
			memo[slot] = 0
			return 0
		}
	}

	for split in 1..<span {
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

@(export)
scramble_strings :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	n_value := values[0]
	if n_value < 0 || n_value > MAX_LENGTH do return -1
	n := int(n_value)
	if length != c.size_t(2 * n + 1) do return -1
	for index in 1..<int(length) {
		if values[index] < 97 || values[index] > 122 do return -1
	}

	memo: [MEMO_SIZE]i64
	for index in 0..<MEMO_SIZE do memo[index] = -1
	return scramble_rec(values, 1, 1 + n, 0, 0, n, &memo[0])
}
