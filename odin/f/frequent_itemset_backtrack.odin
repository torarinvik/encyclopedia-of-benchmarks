package frequent_itemset_backtrack

import "core:c"

Context :: struct { minimum: i64, words: [511]i64, records: int }

enumerate :: proc "contextless" (ctx: ^Context, rows: [^]i64, row_count, item_count, start_item: int, prefix: i64) {
	for item := start_item; item < item_count; item += 1 {
		bit := i64(1) << u32(item)
		projected: [16]i64
		projected_count := 0
		for row := 0; row < row_count; row += 1 {
			if (rows[row] & bit) != 0 { projected[projected_count] = rows[row]; projected_count += 1 }
		}
		if i64(projected_count) < ctx.minimum do continue
		mask := prefix | bit
		at := 1 + 2 * ctx.records
		ctx.words[at] = mask; ctx.words[at + 1] = i64(projected_count); ctx.records += 1
		enumerate(ctx, &projected[0], projected_count, item_count, item + 1, mask)
	}
}

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

frequent_itemset_backtrack :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 19 do return -1
	item_count0, row_count0, minimum := input[0], input[1], input[2]
	if item_count0 < 1 || item_count0 > 8 || row_count0 < 1 || row_count0 > 16 || minimum < 1 || minimum > row_count0 || length != c.size_t(3+row_count0) do return -1
	item_count, row_count := int(item_count0), int(row_count0)
	limit := i64(1) << u32(item_count)
	rows: [16]i64
	for i := 0; i < row_count; i += 1 {
		mask := input[3+i]
		if mask < 0 || mask >= limit do return -1
		rows[i] = mask
	}
	ctx := Context{minimum = minimum}
	enumerate(&ctx, &rows[0], row_count, item_count, 0, 0)
	ctx.words[0] = i64(ctx.records)
	word_count := 1 + 2 * ctx.records
	bytes := 8 * word_count
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < word_count; i += 1 { put_i64(output, i, ctx.words[i]) }
	return i64(bytes)
}
