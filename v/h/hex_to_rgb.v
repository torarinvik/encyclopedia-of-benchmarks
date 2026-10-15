module hex_to_rgb

fn hex_nibble(value i64) i64 {
	if value >= 48 && value <= 57 { return value - 48 }
	if value >= 65 && value <= 70 { return value - 65 + 10 }
	if value >= 97 && value <= 102 { return value - 97 + 10 }
	return -1
}

@[export: 'hex_to_rgb']
pub fn hex_to_rgb(input &i64, length usize) i64 {
	if length != 6 { return -1 }
	mut packed_rgb := i64(0)
	for index in 0 .. 6 {
		nibble := hex_nibble(unsafe { input[index] })
		if nibble < 0 { return -1 }
		packed_rgb = (packed_rgb << 4) | nibble
	}
	return packed_rgb
}
