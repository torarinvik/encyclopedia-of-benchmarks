package multikey_quick_sort

import "core:c"

MAX_STRINGS :: 32
MAX_STRING_LENGTH :: 16
MAX_INPUT_WORDS :: 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH)
MAX_PARSEABLE_INPUT_WORDS :: MAX_INPUT_WORDS + 1
MAX_OUTPUT_BYTES :: 4 * MAX_INPUT_WORDS

String_Record :: struct { length: int, bytes: [MAX_STRING_LENGTH]u8 }

char_at :: proc(value: String_Record, depth: int) -> int {
	if depth < value.length do return int(value.bytes[depth])
	return 0
}
median3 :: proc(a, b, c: int) -> int {
	if a < b { if b < c do return b; if a < c do return c; return a }
	if b > c do return b
	if a < c do return a
	return c
}
compare_from_depth :: proc(left, right: String_Record, depth_start: int) -> int {
	depth := depth_start
	for depth < left.length && depth < right.length && left.bytes[depth] == right.bytes[depth] { depth += 1 }
	a := char_at(left, depth); b := char_at(right, depth)
	return (a > b ? 1 : 0) - (a < b ? 1 : 0)
}
insertion_sort :: proc(values: []String_Record, depth: int) {
	for i := 1; i < len(values); i += 1 {
		value := values[i]
		j := i
		for j > 0 && compare_from_depth(values[j-1], value, depth) > 0 {
			values[j] = values[j-1]
			j -= 1
		}
		values[j] = value
	}
}
swap_records :: proc(left, right: ^String_Record) {
	temp := left^
	left^ = right^
	right^ = temp
}
multikey_sort :: proc(values: []String_Record, depth: int) {
	count := len(values)
	if count < 10 { insertion_sort(values, depth); return }
	mid := count / 2
	var pivot: int
	if count > 30 {
		delta := count / 8
		pivot = median3(
			median3(char_at(values[0], depth), char_at(values[delta], depth), char_at(values[2*delta], depth)),
			median3(char_at(values[mid-delta], depth), char_at(values[mid], depth), char_at(values[mid+delta], depth)),
			median3(char_at(values[count-1-2*delta], depth), char_at(values[count-1-delta], depth), char_at(values[count-1], depth)))
	} else { pivot = median3(char_at(values[0], depth), char_at(values[mid], depth), char_at(values[count-1], depth)) }
	less, scan, greater := 0, 0, count
	for scan < greater {
		key := char_at(values[scan], depth)
		if key < pivot { swap_records(&values[less], &values[scan]); less += 1; scan += 1 }
		else if key > pivot { greater -= 1; swap_records(&values[scan], &values[greater]) }
		else { scan += 1 }
	}
	multikey_sort(values[:less], depth)
	if pivot != 0 do multikey_sort(values[less:greater], depth+1)
	multikey_sort(values[greater:], depth)
}
put_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
multikey_quick_sort :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_WORDS) do return -1
	count_raw := input[0]
	if count_raw < 0 || count_raw > MAX_STRINGS do return -1
	count := int(count_raw)
	values: [MAX_STRINGS]String_Record
	pos := 1
	for i := 0; i < count; i += 1 {
		if pos >= int(length) || input[pos] < 0 || input[pos] > MAX_STRING_LENGTH do return -1
		string_length := int(input[pos]); pos += 1
		if pos + string_length > int(length) do return -1
		values[i].length = string_length
		for j := 0; j < string_length; j += 1 {
			byte := input[pos]; pos += 1
			if byte < 1 || byte > 127 do return -1
			values[i].bytes[j] = u8(byte)
		}
	}
	if pos != int(length) do return -1
	bytes := int(length) * 4
	if output == nil || capacity < c.size_t(bytes) do return -2
	multikey_sort(values[:count], 0)
	buffer: [MAX_OUTPUT_BYTES]u8
	word := 0
	put_i32_le(&buffer[0], word*4, count_raw); word += 1
	for i := 0; i < count; i += 1 {
		put_i32_le(&buffer[0], word*4, i32(values[i].length)); word += 1
		for j := 0; j < values[i].length; j += 1 { put_i32_le(&buffer[0], word*4, i32(values[i].bytes[j])); word += 1 }
	}
	for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
	return i64(bytes)
}
