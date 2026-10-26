module beebs_lcdnum

const input_bytes = 5
const segment_masks = [16]u8{0x00,0x24,0x5d,0x6d,0x2e,0x5d,0x7b,0x25,0x7f,0x6f,0x3f,0x7a,0x53,0x7c,0x5b,0x1b}

@[export: 'beebs_lcdnum']
pub fn beebs_lcdnum(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length != input_bytes { return -1 }
	for i in 0 .. input_bytes {
		value := unsafe { values[i] }
		if value < 0 || value > 255 { return -1 }
	}
	if unsafe { output == nil } || capacity < input_bytes { return -2 }
	for i in 0 .. input_bytes {
		value := unsafe { values[i] }
		unsafe { output[i] = segment_masks[int(value & 0x0f)] }
	}
	return input_bytes
}
