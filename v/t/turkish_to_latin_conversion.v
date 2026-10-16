fn continuation(byte u8) bool { return byte >= 0x80 && byte <= 0xbf }

fn decode_utf8(bytes []u8, index int) i64 {
	first := bytes[index]
	if first <= 0x7f { return i64(first) * 8 + 1 }
	if first >= 0xc2 && first <= 0xdf {
		if index + 1 >= bytes.len || !continuation(bytes[index + 1]) { return -1 }
		codepoint := (u32(first & 0x1f) << 6) | u32(bytes[index + 1] & 0x3f)
		return i64(codepoint) * 8 + 2
	}
	if first >= 0xe0 && first <= 0xef {
		if index + 2 >= bytes.len { return -1 }
		second, third := bytes[index + 1], bytes[index + 2]
		if !continuation(second) || !continuation(third) || (first == 0xe0 && second < 0xa0) ||
			(first == 0xed && second >= 0xa0) { return -1 }
		codepoint := (u32(first & 0x0f) << 12) | (u32(second & 0x3f) << 6) | u32(third & 0x3f)
		return i64(codepoint) * 8 + 3
	}
	if first >= 0xf0 && first <= 0xf4 {
		if index + 3 >= bytes.len { return -1 }
		second, third, fourth := bytes[index + 1], bytes[index + 2], bytes[index + 3]
		if !continuation(second) || !continuation(third) || !continuation(fourth) ||
			(first == 0xf0 && second < 0x90) || (first == 0xf4 && second > 0x8f) { return -1 }
		codepoint := (u32(first & 0x07) << 18) | (u32(second & 0x3f) << 12) |
			(u32(third & 0x3f) << 6) | u32(fourth & 0x3f)
		return i64(codepoint) * 8 + 4
	}
	return -1
}

fn map_turkish(codepoint u32) u8 {
	return match codepoint {
		0x0131 { u8(`i`) } 0x0130 { u8(`I`) }
		0x00fc { u8(`u`) } 0x00dc { u8(`U`) }
		0x00f6 { u8(`o`) } 0x00d6 { u8(`O`) }
		0x015f { u8(`s`) } 0x015e { u8(`S`) }
		0x00e7 { u8(`c`) } 0x00c7 { u8(`C`) }
		0x011f { u8(`g`) } 0x011e { u8(`G`) }
		else { u8(0) }
	}
}

@[export: 'turkish_to_latin_conversion']
pub fn turkish_to_latin_conversion(input &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	max_text_bytes := 1024
	if length < 1 || length > usize(max_text_bytes + 1) || isnil(input) { return -1 }
	byte_length := unsafe { input[0] }
	if byte_length < 0 || byte_length > max_text_bytes || length != usize(byte_length + 1) { return -1 }
	text_length := int(byte_length)
	mut bytes := []u8{len: text_length, init: 0}
	for index in 0 .. text_length {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 255 { return -1 }
		bytes[index] = u8(value)
	}
	mut result_length := 0
	mut index := 0
	for index < text_length {
		decoded := decode_utf8(bytes, index)
		if decoded < 0 { return -1 }
		codepoint := u32(decoded / 8)
		width := int(decoded % 8)
		if map_turkish(codepoint) != 0 { result_length++ } else { result_length += width }
		index += width
	}
	if usize(result_length) > output_capacity || (result_length > 0 && isnil(output)) { return -2 }
	mut written := 0
	index = 0
	for index < text_length {
		decoded := decode_utf8(bytes, index)
		codepoint := u32(decoded / 8)
		width := int(decoded % 8)
		mapped := map_turkish(codepoint)
		if mapped != 0 {
			unsafe { output[written] = mapped }
			written++
		} else {
			for byte in 0 .. width {
				unsafe { output[written + byte] = bytes[index + byte] }
			}
			written += width
		}
		index += width
	}
	return i64(result_length)
}
