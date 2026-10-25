// Independent bounded port of FreeBench pcompress2; upstream license grant not found.
package pcompress2

import "core:c"

MAX_LENGTH :: 32
MAX_OUTPUT :: 8 + MAX_LENGTH * 16
SYMBOLS :: 257

Bit_Writer :: struct { bytes: [^]u8, length: int, buffer: u8, bits_to_go: int }

rotation_less :: proc(input: [^]u8, n, left, right: int) -> bool {
	for offset := 0; offset < n; offset += 1 {
		a := input[(left + offset) % n]
		b := input[(right + offset) % n]
		if a != b do return a < b
	}
	return left < right
}

output_bit :: proc(w: ^Bit_Writer, bit: bool) {
	w.buffer >>= 1
	if bit do w.buffer |= 0x80
	w.bits_to_go -= 1
	if w.bits_to_go == 0 { w.bytes[w.length] = w.buffer; w.length += 1; w.bits_to_go = 8 }
}

bit_plus_follow :: proc(w: ^Bit_Writer, bit: bool, follow: ^int) {
	output_bit(w, bit)
	for follow^ > 0 { output_bit(w, !bit); follow^ -= 1 }
}

encode_symbol :: proc(symbol: int, cum: ^[258]int, low, high: ^u32, follow: ^int, w: ^Bit_Writer) {
	span := u64(high^ - low^) + 1
	old_low := low^
	high^ = old_low + u32(span * u64(cum[symbol - 1]) / u64(cum[0])) - 1
	low^ = old_low + u32(span * u64(cum[symbol]) / u64(cum[0]))
	for {
		if high^ < 32768 { bit_plus_follow(w, false, follow) }
		else if low^ >= 32768 { bit_plus_follow(w, true, follow); low^ -= 32768; high^ -= 32768 }
		else if low^ >= 16384 && high^ < 49152 { follow^ += 1; low^ -= 16384; high^ -= 16384 }
		else { break }
		low^ *= 2
		high^ = high^ * 2 + 1
	}
}

update_model :: proc(symbol: int, char_to_index: ^[256]int, index_to_char: ^[258]u8,
		freq: ^[258]int, cum: ^[258]int) {
	if cum[0] == 16383 {
		total := 0
		for i := SYMBOLS; i >= 0; i -= 1 { freq[i] = (freq[i] + 1) / 2; cum[i] = total; total += freq[i] }
	}
	i := symbol
	for freq[i] == freq[i - 1] { i -= 1 }
	if i < symbol {
		a := index_to_char[i]; b := index_to_char[symbol]
		index_to_char[i] = b; index_to_char[symbol] = a
		char_to_index[int(a)] = symbol; char_to_index[int(b)] = i
	}
	freq[i] += 1
	for i > 0 { i -= 1; cum[i] += 1 }
}

arithmetic_encode :: proc(data: [^]u8, count: int, encoded: [^]u8) -> int {
	char_to_index: [256]int
	index_to_char: [258]u8
	freq: [258]int
	cum: [258]int
	for i := 0; i < 256; i += 1 { char_to_index[i] = i + 1; index_to_char[i + 1] = u8(i) }
	for i := 0; i <= SYMBOLS; i += 1 { freq[i] = 1; cum[i] = SYMBOLS - i }
	freq[0] = 0
	w := Bit_Writer{bytes = encoded, bits_to_go = 8}
	low: u32 = 0; high: u32 = 65535; follow := 0
	for i := 0; i < count; i += 1 {
		symbol := char_to_index[int(data[i])]
		encode_symbol(symbol, &cum, &low, &high, &follow, &w)
		update_model(symbol, &char_to_index, &index_to_char, &freq, &cum)
	}
	encode_symbol(257, &cum, &low, &high, &follow, &w)
	follow += 1
	bit_plus_follow(&w, low < 16384, &follow)
	w.bytes[w.length] = w.buffer >> u8(w.bits_to_go)
	w.length += 1
	return w.length
}

compress_bounded :: proc(input: [^]u8, n: int, output: [^]u8) -> int {
	order: [MAX_LENGTH]int
	last: [MAX_LENGTH]u8
	rle: [MAX_LENGTH * 2]u8
	rle_length := 0
	for i := 0; i < n; i += 1 { order[i] = i }
	for i := 1; i < n; i += 1 {
		key := order[i]; j := i
		for j > 0 && rotation_less(input, n, key, order[j - 1]) { order[j] = order[j - 1]; j -= 1 }
		order[j] = key
	}
	primary := 0
	for row := 0; row < n; row += 1 { if order[row] == 0 do primary = row; last[row] = input[(order[row] + n - 1) % n] }
	for i := 0; i < n; {
		count := 1; value := last[i]
		for i + count < n && last[i + count] == value && count < 127 { count += 1 }
		if count == 1 {
			for i + count < n && last[i + count - 1] != last[i + count] && (i + count + 1 == n || last[i + count] != last[i + count + 1]) { count += 1 }
			rle[rle_length] = u8(count & 0x7f); rle_length += 1
			for j := 0; j < count; j += 1 { rle[rle_length] = last[i + j]; rle_length += 1 }
			i += count
		} else { rle[rle_length] = u8(count | 0x80); rle_length += 1; rle[rle_length] = value; rle_length += 1; i += count }
	}
	output[0] = u8(n); output[1] = 0; output[2] = 0; output[3] = 0
	output[4] = u8(primary); output[5] = 0; output[6] = 0; output[7] = 0
	payload: [MAX_OUTPUT]u8
	payload_length := arithmetic_encode(&rle[0], rle_length, &payload[0])
	for i := 0; i < payload_length; i += 1 { output[8 + i] = payload[i] }
	return 8 + payload_length
}

@(export)
pcompress2 :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || values[0] < 1 || values[0] > MAX_LENGTH do return -1
	n := int(values[0]); if length != c.size_t(n + 1) do return -1
	input: [MAX_LENGTH]u8
	for i := 0; i < n; i += 1 { if values[i + 1] < 0 || values[i + 1] > 255 do return -1; input[i] = u8(values[i + 1]) }
	encoded: [MAX_OUTPUT]u8
	encoded_length := compress_bounded(&input[0], n, &encoded[0])
	if output == nil || output_capacity < c.size_t(encoded_length) do return -2
	for i := 0; i < encoded_length; i += 1 { output[i] = encoded[i] }
	return i64(encoded_length)
}
