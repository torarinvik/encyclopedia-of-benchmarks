package runenumerate

import "core:c"

MAX_N :: 24
MAX_RUNS :: 144
STRIDE :: MAX_N + 1

Run :: struct { period, left, right: int }

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
runenumerate :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_N + 1 do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	text: [MAX_N]int
	for i := 0; i < n; i += 1 {
		if input[i + 1] < 0 || input[i + 1] >= 26 do return -1
		text[i] = int(input[i + 1])
	}
	if output == nil do return -2

	stride := STRIDE
	lcp: [STRIDE * STRIDE]int
	for i := n - 1; i >= 0; i -= 1 {
		for j := n - 1; j > i; j -= 1 {
			if text[i] == text[j] { lcp[i * stride + j] = 1 + lcp[(i + 1) * stride + j + 1] }
		}
	}
	runs: [MAX_RUNS]Run
	count := 0
	for period := 1; period <= n / 2; period += 1 {
		i := period
		for i < n {
			if text[i] != text[i - period] { i += 1; continue }
			first := i
			for i < n && text[i] == text[i - period] { i += 1 }
			left := first - period
			right := i
			if right - left < 2 * period do continue
			minimal := true
			for smaller := 1; smaller < period; smaller += 1 {
				if lcp[left * stride + left + smaller] >= right - left - smaller {
					minimal = false
					break
				}
			}
			if minimal && count < MAX_RUNS {
				runs[count] = Run{period, left, right}
				count += 1
			}
		}
	}
	for i := 1; i < count; i += 1 {
		value := runs[i]
		j := i
		for j > 0 && (runs[j - 1].period > value.period ||
			(runs[j - 1].period == value.period && runs[j - 1].left > value.left) ||
			(runs[j - 1].period == value.period && runs[j - 1].left == value.left && runs[j - 1].right > value.right)) {
			runs[j] = runs[j - 1]
			j -= 1
		}
		runs[j] = value
	}
	needed := 8 + 24 * count
	if capacity < c.size_t(needed) do return -2
	store_i64_le(output, 0, i64(count))
	for i := 0; i < count; i += 1 {
		offset := 8 + 24 * i
		store_i64_le(output, offset, i64(runs[i].period))
		store_i64_le(output, offset + 8, i64(runs[i].left))
		store_i64_le(output, offset + 16, i64(runs[i].right))
	}
	return i64(needed)
}
