module versabench_8b10b

const max_words = 160
const max_output_bytes = 18
const raw5 = [
	0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
	0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
	0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
	0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2,
]
const raw3 = [0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c]

fn encode_one(packed_word u32, mut disparity &u32) u32 {
	data := packed_word & u32(0xff)
	k := packed_word >> 8
	index5 := int(data >> 3)
	index3 := int(data & u32(7))
	mut lookup5 := u32(raw5[index5])
	mut lookup3 := u32(raw3[index3])
	if k == 1 && index5 == 7 { lookup5 = 0x04e2 }
	if k == 1 {
		if index3 >= 2 && index3 <= 5 {
			lookup3 = (lookup3 & ~u32(0x1000)) | u32(0x0800)
		} else if index3 == 7 {
			lookup3 = 0x040d
		}
	}

	mut result := u32(0)
	mut disparity1 := u32(0)
	if (lookup5 & u32(0x1000)) != 0 {
		result = lookup5 & u32(0x03e2)
		disparity1 = disparity
	} else {
		code5 := lookup5 & u32(0x03e2)
		plus5 := if (lookup5 & u32(0x0800)) != 0 { u32(1) } else { u32(0) }
		flip5 := if (lookup5 & u32(0x0400)) != 0 { u32(1) } else { u32(0) }
		result = if disparity == plus5 { code5 } else { code5 ^ u32(0x03e2) }
		disparity1 = disparity ^ flip5
	}

	if (lookup3 & u32(0x1000)) != 0 {
		result |= lookup3 & u32(0x001d)
		disparity = disparity1
	} else {
		code3 := lookup3 & u32(0x001d)
		plus3 := if (lookup3 & u32(0x0800)) != 0 { u32(1) } else { u32(0) }
		flip3 := if (lookup3 & u32(0x0400)) != 0 { u32(1) } else { u32(0) }
		result |= if disparity1 == plus3 { code3 } else { code3 ^ u32(0x001d) }
		disparity = disparity1 ^ flip3
	}
	return result
}

fn append_line(value u32, mut staged [max_output_bytes]u8, mut used int) {
	hex := '0123456789ABCDEF'.bytes()
	for digit in 0 .. 8 {
		shift := (7 - digit) * 4
		staged[used] = hex[int((value >> shift) & 15)]
		used++
	}
	staged[used] = u8('\n')
	used++
}

@[export: 'versabench_8b10b']
pub fn versabench_8b10b(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if length > max_words || (length > 0 && values == nil) { return -1 }
		for index in 0 .. int(length) {
			value := values[index]
			if value < 0 || value > 511 { return -1 }
		}
		sample_count := if length == 0 { usize(0) } else { usize(1) + (length - 1) / 128 }
		required := sample_count * 9
		if required > 0 && (output == nil || output_capacity < required) { return -2 }

		mut staged := [max_output_bytes]u8{}
		mut used := 0
		mut disparity := u32(0)
		for pass_index in 0 .. int(length) {
			for index in 0 .. int(length) {
				encoded := encode_one(u32(values[index]), mut disparity)
				if pass_index + 1 == int(length) && index % 128 == 0 {
					append_line(encoded, mut staged, mut used)
				}
			}
		}
		for index in 0 .. int(required) { output[index] = staged[index] }
		return i64(used)
	}
}
