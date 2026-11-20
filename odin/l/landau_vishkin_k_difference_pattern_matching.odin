package landau_vishkin_k_difference_pattern_matching

import "core:c"

MAX_PATTERN :: 16
MAX_TEXT :: 32
MAX_ERRORS :: 2
MAX_VALID_INPUT :: 3 + MAX_PATTERN + MAX_TEXT
MAX_PARSEABLE_INPUT :: MAX_VALID_INPUT + 1
DIAGONALS :: MAX_TEXT + MAX_ERRORS + 3
COSTS :: MAX_ERRORS + 2

landau_vishkin_k_difference_pattern_matching :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t
) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT do return -1
	raw_m, raw_n, raw_k := input[0], input[1], input[2]
	if raw_m < 1 || raw_m > MAX_PATTERN || raw_n < 0 || raw_n > MAX_TEXT ||
		raw_k < 0 || raw_k > MAX_ERRORS || raw_k >= raw_m do return -1
	m, n, k := int(raw_m), int(raw_n), int(raw_k)
	if length != c.size_t(3 + m + n) do return -1
	for index := 0; index < m; index += 1 {
		symbol := input[3 + index]
		if symbol < 0 || symbol > 3 do return -1
	}
	for index := 0; index < n; index += 1 {
		symbol := input[3 + m + index]
		if symbol < 0 || symbol > 3 do return -1
	}
	if output == nil || capacity < c.size_t(n) do return -2

	frontier: [DIAGONALS][COSTS]i64
	for diagonal in 0..<DIAGONALS {
		for cost in 0..<COSTS {
			frontier[diagonal][cost] = -1
		}
	}
	for d := -(k + 1); d < 0; d += 1 {
		magnitude := -d
		base := d + MAX_ERRORS + 1
		frontier[base][magnitude] = i64(magnitude - 1)
		frontier[base][magnitude - 1] = i64(magnitude - 2)
	}

	staged: [MAX_TEXT]u8
	for errors := 0; errors <= k; errors += 1 {
		for d := -errors; d <= n; d += 1 {
			base := d + MAX_ERRORS + 1
			row := max(frontier[base][errors] + 1,
				max(frontier[base - 1][errors], frontier[base + 1][errors] + 1))
			row = min(row, raw_m)
			for row < raw_m {
				text_index := row + i64(d)
				if text_index < 0 || text_index >= raw_n ||
					input[3 + int(row)] != input[3 + m + int(text_index)] do break
				row += 1
			}
			frontier[base][errors + 1] = row
			if row == raw_m {
				endpoint := i64(d) + raw_m
				if endpoint >= 1 && endpoint <= raw_n do staged[int(endpoint - 1)] = 1
			}
		}
	}
	for index in 0..<n do output[index] = staged[index]
	return i64(n)
}
