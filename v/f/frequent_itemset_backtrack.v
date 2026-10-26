module frequent_itemset_backtrack

struct Context {
	minimum i64
	mut:
	words [511]i64
	records int
}

fn enumerate(mut ctx Context, rows []i64, item_count int, start_item int, prefix i64) {
	for item := start_item; item < item_count; item++ {
		bit := i64(1) << u32(item)
		mut projected := []i64{cap: rows.len}
		for row in rows { if (row & bit) != 0 { projected << row } }
		if i64(projected.len) < ctx.minimum { continue }
		mask := prefix | bit
		at := 1 + 2 * ctx.records
		ctx.words[at] = mask; ctx.words[at + 1] = i64(projected.len); ctx.records++
		enumerate(mut ctx, projected, item_count, item + 1, mask)
	}
}

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'frequent_itemset_backtrack']
pub fn frequent_itemset_backtrack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 19 { return -1 }
	unsafe {
		item_count0, row_count0, minimum := input[0], input[1], input[2]
		if item_count0 < 1 || item_count0 > 8 || row_count0 < 1 || row_count0 > 16 || minimum < 1 || minimum > row_count0 || length != usize(3+row_count0) { return -1 }
		item_count, row_count := int(item_count0), int(row_count0)
		limit := i64(1) << u32(item_count)
		mut rows := []i64{cap: row_count}
		for i in 0 .. row_count {
			mask := input[3+i]
			if mask < 0 || mask >= limit { return -1 }
			rows << mask
		}
		mut ctx := Context{minimum: minimum}
		enumerate(mut ctx, rows, item_count, 0, 0)
		ctx.words[0] = i64(ctx.records)
		word_count := 1 + 2 * ctx.records
		bytes := word_count * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. word_count { put_i64(mut output, i, ctx.words[i]) }
		return i64(bytes)
	}
}
