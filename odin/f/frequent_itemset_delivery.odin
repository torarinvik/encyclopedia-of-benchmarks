package frequent_itemset_delivery

import "core:c"

put_u64 :: proc(out: [^]u8, word: int, value: u64) {
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((value >> u64(8*b)) & 255) }
}

frequent_itemset_delivery :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 69 do return -1
	n0, rows0, minimum, tail, prefix0 := input[0], input[1], input[2], input[3], input[4]
	if n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > 64 || minimum < 1 || minimum > rows0 || length != c.size_t(5+rows0) do return -1
	if tail < -1 || tail >= n0 || prefix0 < 0 do return -1
	n, row_count := int(n0), int(rows0)
	limit := u64(1) << u32(n)
	prefix := u64(prefix0)
	if prefix >= limit || (tail == -1 && prefix != 0) || (tail >= 0 && (((prefix >> u32(tail)) & 1) == 0 || (prefix >> u32(tail+1)) != 0)) do return -1
	occurrences: [8]u64
	supports: [8]u64
	for item := 0; item < n; item += 1 { occurrences[item] = 0; supports[item] = 0 }
	for row := 0; row < row_count; row += 1 {
		row0 := input[5+row]
		if row0 < 0 || u64(row0) >= limit do return -1
		mask := u64(row0)
		if (mask & prefix) != prefix do continue
		for item := int(tail+1); item < n; item += 1 {
			if (mask & (u64(1) << u32(item))) != 0 { occurrences[item] |= u64(1) << u32(row); supports[item] += 1 }
		}
	}
	words: [25]u64
	for i := 0; i < len(words); i += 1 { words[i] = 0 }
	records := 0
	for item := int(tail+1); item < n; item += 1 {
		if supports[item] < u64(minimum) do continue
		at := 1 + 3*records
		words[at] = u64(item); words[at+1] = occurrences[item]; words[at+2] = supports[item]; records += 1
	}
	words[0] = u64(records)
	word_count := 1 + 3*records
	bytes := 8*word_count
	if bytes > 200 do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < word_count; i += 1 { put_u64(output, i, words[i]) }
	return i64(bytes)
}
