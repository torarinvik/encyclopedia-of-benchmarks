const catalan_counts = [1, 1, 2, 5, 14, 42, 132]

fn generate_parentheses(pairs int, opens int, closes int, mut path []u8, mut output []u8, mut index int) {
	if opens + closes == pairs * 2 {
		for i in 0 .. pairs * 2 { output[2 + index * pairs * 2 + i] = path[i] }
		index++
		return
	}
	if opens < pairs { path[opens + closes] = 40; generate_parentheses(pairs, opens + 1, closes, mut path, mut output, mut index) }
	if closes < opens { path[opens + closes] = 41; generate_parentheses(pairs, opens, closes + 1, mut path, mut output, mut index) }
}

@[export: 'parentheses_generator']
pub fn parentheses_generator(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n != 1 || v[0] < 0 || v[0] > 6 { return -1 }
		pairs := int(v[0]); needed := 2 + catalan_counts[pairs] * 2 * pairs
		if output == nil || capacity < needed { return -2 }
		output[0] = u8(catalan_counts[pairs]); output[1] = u8(catalan_counts[pairs] >> 8)
		mut path := []u8{len: 12}; mut index := 0
		mut out_slice := unsafe { output[0..capacity] }
		generate_parentheses(pairs, 0, 0, mut path, mut out_slice, mut index)
		return i64(needed)
	}
}
