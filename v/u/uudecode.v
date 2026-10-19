const max_input_bytes = usize(4096)
const max_output_bytes = usize(2949)

fn scan(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length > max_input_bytes { return -1 }
		for i in 0 .. int(length) {
			if input[i] < 0 || input[i] > 255 { return -1 }
		}
		header := 'begin 755 uustart.file \n'
		if length < usize(header.len + 5) { return -1 }
		for i in 0 .. header.len {
			if input[i] != i64(header[i]) { return -1 }
		}
		mut cursor := usize(header.len)
		mut total := usize(0)
		for cursor < length {
			marker := input[cursor]
			cursor++
			if marker == 32 {
				if cursor + 4 != length || input[cursor] != 10 || input[cursor + 1] != 101 ||
					input[cursor + 2] != 110 || input[cursor + 3] != 100 { return -1 }
				if total > max_output_bytes { return -1 }
				return i64(total)
			}
			count := marker - 32
			if count < 1 || count > 45 { return -1 }
			encoded := usize(4 * ((count + 2) / 3))
			if cursor + encoded >= length || input[cursor + encoded] != 10 { return -1 }
			for i in 0 .. int(encoded) {
				if input[cursor + usize(i)] < 32 || input[cursor + usize(i)] > 95 { return -1 }
			}
			total += usize(count)
			if total > max_output_bytes { return -1 }
			cursor += encoded + 1
		}
		return -1
	}
}

@[export: 'uudecode']
pub fn uudecode(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length > max_input_bytes { return -1 }
	decoded_length := scan(input, length)
	if decoded_length < 0 { return -1 }
	unsafe {
		if output == nil || capacity < usize(decoded_length) { return -2 }
		mut cursor := usize('begin 755 uustart.file \n'.len)
		mut written := usize(0)
		for {
			count := usize(input[cursor] - 32)
			cursor++
			if count == 0 { break }
			encoded := 4 * ((count + 2) / 3)
			mut emitted := usize(0)
			for _ in 0 .. int(encoded / 4) {
				a := u32(input[cursor] - 32)
				b := u32(input[cursor + 1] - 32)
				c := u32(input[cursor + 2] - 32)
				d := u32(input[cursor + 3] - 32)
				cursor += 4
				output[written] = u8(((a << 2) | (b >> 4)) & 255); written++
				emitted++
				if emitted < count {
					output[written] = u8(((b << 4) | (c >> 2)) & 255); written++; emitted++
				}
				if emitted < count {
					output[written] = u8(((c << 6) | d) & 255); written++; emitted++
				}
			}
			cursor++
		}
		return i64(written)
	}
}
