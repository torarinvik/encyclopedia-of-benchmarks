package frequent_itemset_conditional_db_reduction

import "core:c"

put_u64 :: proc(out: [^]u8, word: int, value: u64) {
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((value >> u64(8*b)) & 255) }
}

frequent_itemset_conditional_db_reduction :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 69 do return -1
	n0, rows0, minimum, tail, prefix0 := input[0], input[1], input[2], input[3], input[4]
	if n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > 64 || minimum < 1 || minimum > rows0 || length != c.size_t(5+rows0) do return -1
	if tail < -1 || tail >= n0 || prefix0 < 0 do return -1
	n, row_count := int(n0), int(rows0)
	limit := u64(1) << u32(n)
	prefix := u64(prefix0)
	if prefix >= limit || (tail == -1 && prefix != 0) || (tail >= 0 && (((prefix >> u32(tail)) & 1) == 0 || (prefix >> u32(tail+1)) != 0)) do return -1
	selected: [64]u64
	support: [8]u64
	for i := 0; i < 64; i += 1 { selected[i] = 0 }
	for i := 0; i < 8; i += 1 { support[i] = 0 }
	selected_count := 0
	for row := 0; row < row_count; row += 1 {
		row0 := input[5+row]
		if row0 < 0 || u64(row0) >= limit do return -1
		mask := u64(row0)
		if (mask & prefix) != prefix do continue
		selected[selected_count] = mask; selected_count += 1
		for item := int(tail+1); item < n; item += 1 {
			if (mask & (u64(1) << u32(item))) != 0 { support[item] += 1 }
		}
	}
	if selected_count < int(minimum) do return -1
	keep := u64(0)
	if tail >= 0 { keep = u64(1) << u32(tail) }
	for item := int(tail+1); item < n; item += 1 {
		if support[item] >= u64(minimum) { keep |= u64(1) << u32(item) }
	}
	below := u64(0)
	if tail > 0 { below = (u64(1) << u32(tail)) - 1 }
	masks: [64]u64
	counts: [64]u64
	for i := 0; i < 64; i += 1 { masks[i] = 0; counts[i] = 0 }
	distinct := 0
	for row := 0; row < selected_count; row += 1 {
		reduced := selected[row] & ~below & keep
		at := 0
		for at < distinct && masks[at] != reduced { at += 1 }
		if at == distinct { masks[distinct] = reduced; distinct += 1 }
		counts[at] += 1
	}
	for i := 1; i < distinct; i += 1 {
		saved_mask, saved_count := masks[i], counts[i]
		j := i
		for j > 0 && masks[j-1] > saved_mask { masks[j] = masks[j-1]; counts[j] = counts[j-1]; j -= 1 }
		masks[j], counts[j] = saved_mask, saved_count
	}
	word_count := 1 + 2*distinct
	bytes := 8*word_count
	if bytes > 1032 do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_u64(output, 0, u64(distinct))
	for i := 0; i < distinct; i += 1 { put_u64(output, 1+2*i, masks[i]); put_u64(output, 2+2*i, counts[i]) }
	return i64(bytes)
}
