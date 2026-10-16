fn write_u64(mut out []u8, mut cursor int, x i64) {
	u := u64(x)
	for i in 0 .. 8 { out[cursor + i] = u8((u >> (i * 8)) & 255) }
	cursor += 8
}

fn emit_powerset(values []i64, at int, mut selected []i64, used int, mut output []u8, mut cursor int) {
	if at == values.len {
		output[cursor] = u8(used); cursor++
		for i in 0 .. used { write_u64(mut output, mut cursor, selected[i]) }
		return
	}
	emit_powerset(values, at + 1, mut selected, used, mut output, mut cursor)
	selected[used] = values[at]
	emit_powerset(values, at + 1, mut selected, used + 1, mut output, mut cursor)
}

@[export: 'powerset']
pub fn powerset(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 7 || v[0] < 0 || v[0] > 6 || n != usize(v[0] + 1) { return -1 }
		count := int(v[0]); subsets := 1 << count; needed := 2 + subsets + 8 * count * (subsets / 2)
		for i in 1 .. int(n) { if v[i] < -1_000_000 || v[i] > 1_000_000 { return -1 } }
		if output == nil || capacity < needed { return -2 }
		output[0] = u8(subsets); output[1] = u8(subsets >> 8)
		mut selected := []i64{len: 6}; mut cursor := 2
		mut out_slice := unsafe { output[0..capacity] }
		values := unsafe { v[1..n] }
		emit_powerset(values, 0, mut selected, 0, mut out_slice, mut cursor)
		return i64(needed)
	}
}
