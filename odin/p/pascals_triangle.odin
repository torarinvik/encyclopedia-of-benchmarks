package pascals_triangle

import "core:c"

@(export)
pascals_triangle :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n != 1 || v[0] < 1 || v[0] > 31 do return -1
	rows := int(v[0]); values: [31]i64; values[0] = 1
	for row := 1; row < rows; row += 1 {
		values[row] = 1
		j := row
		for j > 1 { j -= 1; values[j] += values[j - 1] }
	}
	hash := i64(0)
	for i := 0; i < rows; i += 1 { hash = (hash * 31 + values[i]) % 1_000_000_007 }
	return hash
}
