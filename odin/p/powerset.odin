package powerset

import "core:c"

put64 :: proc "contextless" (out: [^]u8, pos: int, x: i64) { u := u64(x); for i := 0; i < 8; i += 1 { out[pos + i] = u8(u >> (i * 8)) } }
emit :: proc "contextless" (v: [^]i64, n, at: int, selected: [^]i64, used: int, out: [^]u8, cursor: ^int) {
	if at == n { out[cursor^] = u8(used); cursor^ += 1; for j := 0; j < used; j += 1 { put64(out, cursor^, selected[j]); cursor^ += 8 }; return }
	emit(v, n, at + 1, selected, used, out, cursor)
	selected[used] = v[at]
	emit(v, n, at + 1, selected, used + 1, out, cursor)
}

@(export)
powerset :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 7 || v[0] < 0 || v[0] > 6 || n != c.size_t(v[0] + 1) do return -1
	count := int(v[0]); subsets := 1 << count; needed := 2 + subsets + 8 * count * (subsets / 2)
	for i := 1; i < int(n); i += 1 { if v[i] < -1_000_000 || v[i] > 1_000_000 do return -1 }
	if out == nil || int(cap) < needed do return -2
	out[0] = u8(subsets); out[1] = u8(subsets >> 8)
	selected: [6]i64; cursor := 2
	emit(v + 1, count, 0, &selected[0], 0, out, &cursor)
	return i64(needed)
}
