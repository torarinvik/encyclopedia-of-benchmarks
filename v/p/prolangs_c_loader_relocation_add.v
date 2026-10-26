module prolangs_c_loader_relocation_add

// Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@[export: 'prolangs_c_loader_relocation_add']
pub fn prolangs_c_loader_relocation_add(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 5 { return -1 }
		half_bytes := input[0]
		delta := input[1]
		if half_bytes < 1 || half_bytes > 6 || delta < -65535 || delta > 65535 { return -1 }
		width := int((half_bytes + 1) / 2)
		if int(length) != 2 + width { return -1 }
		mut field := u32(0)
		for i := 0; i < width; i++ {
			byte := input[2 + i]
			if byte < 0 || byte > 255 { return -1 }
			field = field * 256 + u32(byte)
		}
		adjusted := i64(field) + delta
		if adjusted < 0 { return -1 }
		if output == nil || capacity < usize(width) { return -2 }
		mut result := u32(adjusted)
		for i := width; i > 0; i-- { output[i - 1] = u8(result & 255); result >>= 8 }
		return i64(width)
	}
}
