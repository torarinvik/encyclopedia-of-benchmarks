module frequent_itemset_conditional_db_reduction

fn put_u64(mut output &u8, word int, value u64) {
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((value >> u64(8 * b)) & 255) } }
}

@[export: 'frequent_itemset_conditional_db_reduction']
pub fn frequent_itemset_conditional_db_reduction(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 6 || length > 69 { return -1 }
	unsafe {
		n0, rows0, minimum, tail, prefix0 := input[0], input[1], input[2], input[3], input[4]
		if n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > 64 || minimum < 1 || minimum > rows0 || length != usize(5 + rows0) { return -1 }
		if tail < -1 || tail >= n0 || prefix0 < 0 { return -1 }
		n, row_count := int(n0), int(rows0)
		limit := u64(1) << u32(n)
		prefix := u64(prefix0)
		if prefix >= limit || (tail == -1 && prefix != 0) || (tail >= 0 && (((prefix >> u32(tail)) & 1) == 0 || (prefix >> u32(tail + 1)) != 0)) { return -1 }
		mut selected := [64]u64{}
		mut support := [8]u64{}
		mut selected_count := 0
		for row in 0 .. row_count {
			row0 := input[5 + row]
			if row0 < 0 || u64(row0) >= limit { return -1 }
			mask := u64(row0)
			if (mask & prefix) != prefix { continue }
			selected[selected_count] = mask
			selected_count++
			for item := int(tail + 1); item < n; item++ {
				if (mask & (u64(1) << u32(item))) != 0 { support[item]++ }
			}
		}
		if selected_count < int(minimum) { return -1 }
		mut keep := u64(0)
		if tail >= 0 { keep = u64(1) << u32(tail) }
		for item := int(tail + 1); item < n; item++ {
			if support[item] >= u64(minimum) { keep |= u64(1) << u32(item) }
		}
		below := if tail > 0 { (u64(1) << u32(tail)) - 1 } else { u64(0) }
		mut masks := [64]u64{}
		mut counts := [64]u64{}
		mut distinct := 0
		for row in 0 .. selected_count {
			reduced := selected[row] & ~below & keep
			mut at := 0
			for at < distinct && masks[at] != reduced { at++ }
			if at == distinct { masks[distinct] = reduced; distinct++ }
			counts[at]++
		}
		for i := 1; i < distinct; i++ {
			saved_mask, saved_count := masks[i], counts[i]
			mut j := i
			for j > 0 && masks[j - 1] > saved_mask { masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; j-- }
			masks[j], counts[j] = saved_mask, saved_count
		}
		word_count := 1 + 2 * distinct
		bytes := 8 * word_count
		if bytes > 1032 { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		put_u64(mut output, 0, u64(distinct))
		for i in 0 .. distinct { put_u64(mut output, 1 + 2 * i, masks[i]); put_u64(mut output, 2 + 2 * i, counts[i]) }
		return i64(bytes)
	}
}
