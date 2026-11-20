package punycode_codepoint_sequence_encode

import "core:c"

MAX_POINTS :: 32
MAX_WORDS :: 34
MAX_OUTPUT :: 320

adapt_bias :: proc(delta_input, point_count: i64, first_time: bool) -> i64 {
	delta := delta_input / (if first_time then 700 else 2)
	delta += delta / point_count
	k: i64 = 0
	for delta > 455 {
		delta /= 35
		k += 36
	}
	return k + (36 * delta) / (delta + 38)
}

digit_byte :: proc(digit: i64) -> u8 {
	if digit < 26 do return u8('a' + digit)
	return u8('0' + digit - 26)
}

is_scalar :: proc(point: i64) -> bool {
	return point >= 0 && point <= 0x10ffff && !(point >= 0xd800 && point <= 0xdfff)
}

encode_payload :: proc(points: [^]i64, count: int, staged: [^]u8) -> int {
	basic_count := 0
	for i := 0; i < count; i += 1 {
		if points[i] < 0x80 {
			staged[basic_count] = u8(points[i])
			basic_count += 1
		}
	}
	written := basic_count
	if basic_count != 0 { staged[written] = u8('-'); written += 1 }
	n, delta, bias: i64 = 128, 0, 72
	handled := basic_count
	for handled < count {
		minimum := i64(0x110000)
		for i := 0; i < count; i += 1 {
			if points[i] >= n && points[i] < minimum { minimum = points[i] }
		}
		delta += (minimum - n) * i64(handled + 1)
		n = minimum
		for i := 0; i < count; i += 1 {
			if points[i] < n { delta += 1 }
			if points[i] == n {
				q := delta
				for k := i64(36); ; k += 36 {
					threshold := i64(1)
					if k > bias { threshold = k - bias }
					if k >= bias + 26 { threshold = 26 }
					if q < threshold { staged[written] = digit_byte(q); written += 1; break }
					staged[written] = digit_byte(threshold + (q-threshold)%(36-threshold))
					written += 1
					q = (q - threshold) / (36 - threshold)
				}
				bias = adapt_bias(delta, i64(handled+1), handled == basic_count)
				delta = 0
				handled += 1
			}
		}
		delta += 1
		n += 1
	}
	return written
}

@(export)
punycode_codepoint_sequence_encode :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_WORDS do return -1
	count_word := input[0]
	if count_word < 0 || count_word > MAX_POINTS || length != c.size_t(count_word + 1) do return -1
	count := int(count_word)
	for i := 0; i < count; i += 1 { if !is_scalar(input[i+1]) do return -1 }
	staged: [MAX_OUTPUT]u8
	written := encode_payload(&input[1], count, &staged[0])
	if written > MAX_OUTPUT do return -1
	if written != 0 && (output == nil || capacity < c.size_t(written)) do return -2
	for i := 0; i < written; i += 1 { output[i] = staged[i] }
	return i64(written)
}
