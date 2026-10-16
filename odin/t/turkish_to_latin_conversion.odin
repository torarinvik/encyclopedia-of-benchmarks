package turkish_to_latin_conversion

import "core:c"

continuation :: proc "contextless" (byte: u8) -> bool { return byte >= 0x80 && byte <= 0xBF }

decode_utf8 :: proc "contextless" (bytes: [^]u8, length, index: int,
		codepoint: ^u32, width: ^int) -> bool {
	first := bytes[index]
	if first <= 0x7F { codepoint^ = u32(first); width^ = 1; return true }
	if first >= 0xC2 && first <= 0xDF {
		if index + 1 >= length || !continuation(bytes[index + 1]) { return false }
		codepoint^ = (u32(first & 0x1F) << 6) | u32(bytes[index + 1] & 0x3F)
		width^ = 2; return true
	}
	if first >= 0xE0 && first <= 0xEF {
		if index + 2 >= length { return false }
		second, third := bytes[index + 1], bytes[index + 2]
		if !continuation(second) || !continuation(third) || (first == 0xE0 && second < 0xA0) ||
			(first == 0xED && second >= 0xA0) { return false }
		codepoint^ = (u32(first & 0x0F) << 12) | (u32(second & 0x3F) << 6) | u32(third & 0x3F)
		width^ = 3; return true
	}
	if first >= 0xF0 && first <= 0xF4 {
		if index + 3 >= length { return false }
		second, third, fourth := bytes[index + 1], bytes[index + 2], bytes[index + 3]
		if !continuation(second) || !continuation(third) || !continuation(fourth) ||
			(first == 0xF0 && second < 0x90) || (first == 0xF4 && second > 0x8F) { return false }
		codepoint^ = (u32(first & 0x07) << 18) | (u32(second & 0x3F) << 12) |
			(u32(third & 0x3F) << 6) | u32(fourth & 0x3F)
		width^ = 4; return true
	}
	return false
}

map_turkish :: proc "contextless" (codepoint: u32) -> u8 {
	switch codepoint {
	case 0x0131: return 'i'; case 0x0130: return 'I'
	case 0x00FC: return 'u'; case 0x00DC: return 'U'
	case 0x00F6: return 'o'; case 0x00D6: return 'O'
	case 0x015F: return 's'; case 0x015E: return 'S'
	case 0x00E7: return 'c'; case 0x00C7: return 'C'
	case 0x011F: return 'g'; case 0x011E: return 'G'
	case: return 0
	}
}

@(export)
turkish_to_latin_conversion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_text_bytes :: 1024
	if input == nil || length < 1 || length > max_text_bytes + 1 { return -1 }
	if input[0] < 0 || input[0] > max_text_bytes || length != c.size_t(input[0] + 1) { return -1 }
	text_length := int(input[0])
	bytes: [max_text_bytes]u8
	for index := 0; index < text_length; index += 1 {
		if input[index + 1] < 0 || input[index + 1] > 255 { return -1 }
		bytes[index] = u8(input[index + 1])
	}
	result_length := 0
	index := 0
	for index < text_length {
		codepoint: u32
		width: int
		if !decode_utf8(&bytes[0], text_length, index, &codepoint, &width) { return -1 }
		if map_turkish(codepoint) != 0 { result_length += 1 } else { result_length += width }
		index += width
	}
	if c.size_t(result_length) > output_capacity || (result_length > 0 && output == nil) { return -2 }
	written := 0
	index = 0
	for index < text_length {
		codepoint: u32
		width: int
		_ = decode_utf8(&bytes[0], text_length, index, &codepoint, &width)
		mapped := map_turkish(codepoint)
		if mapped != 0 {
			output[written] = mapped
			written += 1
		} else {
			for byte := 0; byte < width; byte += 1 { output[written + byte] = bytes[index + byte] }
			written += width
		}
		index += width
	}
	return i64(result_length)
}
