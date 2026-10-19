module uuencode

const max_input_bytes = usize(4096)

fn symbol(value u32) u8 {
	return u8(32 + (value & 63))
}

@[export: 'uuencode']
pub fn uuencode(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length > max_input_bytes { return -1 }
	unsafe {
		for i in 0 .. int(length) {
			if input[i] < 0 || input[i] > 255 { return -1 }
		}
		needed := usize(22 + 4 * ((length + 2) / 3) + 2 * ((length + 44) / 45) + 5)
		if output == nil || capacity < needed { return -2 }
		header := 'begin 640 uuencode.c \n'
		trailer := ' \nend'
		mut written := usize(0)
		for i in 0 .. header.len { output[written] = header[i]; written++ }
		mut start := usize(0)
		for start < length {
			mut line_len := length - start
			if line_len > 45 { line_len = 45 }
			stop := start + line_len
			output[written] = symbol(u32(line_len)); written++
			mut index := start
			for index < stop {
				a := u32(input[index])
				has_b := index + 1 < stop
				has_c := index + 2 < stop
				b := if has_b { u32(input[index + 1]) } else { u32(0) }
				c := if has_c { u32(input[index + 2]) } else { u32(0) }
				output[written] = symbol(a >> 2); written++
				output[written] = symbol((a << 4) | (b >> 4)); written++
				output[written] = if has_b { symbol((b << 2) | (c >> 6)) } else { u8('=') }; written++
				output[written] = if has_c { symbol(c) } else { u8('=') }; written++
				index += 3
			}
			output[written] = 10; written++
			start = stop
		}
		for i in 0 .. trailer.len { output[written] = trailer[i]; written++ }
		return i64(written)
	}
}
