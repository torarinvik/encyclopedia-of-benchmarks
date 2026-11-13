fn cdc_reduce(value u32) u16 {
	mut remainder := value
	for step in 0 .. 16 {
		bit := 31 - step
		if remainder & (u32(1) << bit) != 0 { remainder ^= u32(0x1100b) << (bit - 16) }
	}
	return u16(remainder)
}

@[export: 'rabin_content_defined_chunking']
pub fn rabin_content_defined_chunking(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 65 { return -1 }
		if input[0] < 0 || input[0] > 64 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i+1] < 0 || input[i+1] > 255 { return -1 } }
		mut outgoing := [256]u16{}
		for i in 0 .. 256 { outgoing[i] = cdc_reduce(u32(i) << 24) }
		mut fingerprint := u16(0)
		mut boundaries := [64]u8{}
		mut count := 0
		for i in 0 .. n {
			fingerprint = cdc_reduce((u32(fingerprint) << 8) | u32(input[i+1]))
			if i >= 4 { fingerprint ^= outgoing[int(input[i-3])] }
			if fingerprint & 7 == 0 { boundaries[count] = u8(i+1); count++ }
		}
		if n > 0 && (count == 0 || int(boundaries[count-1]) != n) { boundaries[count] = u8(n); count++ }
		if output == nil || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = boundaries[i] }
		return i64(count)
	}
}
