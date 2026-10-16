package parentheses_generator

import "core:c"

COUNTS :: [7]int{1, 1, 2, 5, 14, 42, 132}
generate :: proc "contextless" (pairs, opens, closes: int, path: [^]u8, out: [^]u8, index: ^int) {
	if opens + closes == pairs * 2 {
		for i := 0; i < pairs * 2; i += 1 { out[2 + index^ * pairs * 2 + i] = path[i] }
		index^ += 1
		return
	}
	if opens < pairs { path[opens + closes] = '('; generate(pairs, opens + 1, closes, path, out, index) }
	if closes < opens { path[opens + closes] = ')'; generate(pairs, opens, closes + 1, path, out, index) }
}

@(export)
parentheses_generator :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n != 1 || v[0] < 0 || v[0] > 6 do return -1
	pairs := int(v[0]); needed := 2 + COUNTS[pairs] * 2 * pairs
	if out == nil || int(cap) < needed do return -2
	out[0] = u8(COUNTS[pairs]); out[1] = u8(COUNTS[pairs] >> 8)
	path: [12]u8; index := 0
	generate(pairs, 0, 0, &path[0], out, &index)
	return i64(needed)
}
