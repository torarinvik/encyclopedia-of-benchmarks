module frequent_itemset_delivery

fn put_u64(mut output &u8, word int, value u64) {
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((value >> u64(8 * b)) & 255) } }
}

@[export: 'frequent_itemset_delivery']
pub fn frequent_itemset_delivery(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 6 || length > 69 { return -1 }
	unsafe {
		n0, rows0, minimum, tail, prefix0 := input[0], input[1], input[2], input[3], input[4]
		if n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > 64 || minimum < 1 || minimum > rows0 || length != usize(5 + rows0) { return -1 }
		if tail < -1 || tail >= n0 || prefix0 < 0 { return -1 }
		n, row_count := int(n0), int(rows0)
		limit := u64(1) << u32(n)
		prefix := u64(prefix0)
		if prefix >= limit || (tail == -1 && prefix != 0) || (tail >= 0 && (((prefix >> u32(tail)) & 1) == 0 || (prefix >> u32(tail + 1)) != 0)) { return -1 }
		mut occurrences := [8]u64{}
		mut supports := [8]u64{}
		for row in 0 .. row_count {
			row0 := input[5 + row]
			if row0 < 0 || u64(row0) >= limit { return -1 }
			mask := u64(row0)
			if (mask & prefix) != prefix { continue }
			for item := int(tail + 1); item < n; item++ {
				if (mask & (u64(1) << u32(item))) != 0 { occurrences[item] |= u64(1) << u32(row); supports[item]++ }
			}
		}
		mut words := [25]u64{}
		mut records := 0
		for item := int(tail + 1); item < n; item++ {
			if supports[item] < u64(minimum) { continue }
			at := 1 + 3 * records
			words[at] = u64(item); words[at + 1] = occurrences[item]; words[at + 2] = supports[item]; records++
		}
		words[0] = u64(records)
		word_count := 1 + 3 * records
		bytes := word_count * 8
		if bytes > 200 { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		for word in 0 .. word_count { put_u64(mut output, word, words[word]) }
		return i64(bytes)
	}
}
