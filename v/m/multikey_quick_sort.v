module multikey_quick_sort

const max_strings = 32
const max_string_length = 16
const max_input_words = 1 + max_strings * (1 + max_string_length)
const max_parseable_input_words = max_input_words + 1
const max_output_bytes = 4 * max_input_words

struct StringRecord {
	length int
	bytes [max_string_length]u8
}

fn char_at(value StringRecord, depth int) int {
	if depth < value.length { return int(value.bytes[depth]) }
	return 0
}
fn median3(a int, b int, c int) int {
	if a < b { return if b < c { b } else if a < c { c } else { a } }
	return if b > c { b } else if a < c { a } else { c }
}
fn compare_from_depth(left StringRecord, right StringRecord, depth_start int) int {
	mut depth := depth_start
	for depth < left.length && depth < right.length && left.bytes[depth] == right.bytes[depth] { depth++ }
	a := char_at(left, depth)
	b := char_at(right, depth)
	return int(a > b) - int(a < b)
}
fn insertion_sort(mut values []StringRecord, depth int) {
	if values.len < 2 { return }
	for i in 1 .. values.len {
		value := values[i]
		mut j := i
		for j > 0 && compare_from_depth(values[j - 1], value, depth) > 0 {
			values[j] = values[j - 1]
			j--
		}
		values[j] = value
	}
}
fn multikey_sort(mut values []StringRecord, depth int) {
	count := values.len
	if count < 10 { insertion_sort(mut values, depth); return }
	mid := count / 2
	mut pivot := 0
	if count > 30 {
		delta := count / 8
		pivot = median3(
			median3(char_at(values[0], depth), char_at(values[delta], depth), char_at(values[2 * delta], depth)),
			median3(char_at(values[mid - delta], depth), char_at(values[mid], depth), char_at(values[mid + delta], depth)),
			median3(char_at(values[count - 1 - 2 * delta], depth), char_at(values[count - 1 - delta], depth), char_at(values[count - 1], depth)))
	} else { pivot = median3(char_at(values[0], depth), char_at(values[mid], depth), char_at(values[count - 1], depth)) }
	mut less := 0
	mut scan := 0
	mut greater := count
	for scan < greater {
		key := char_at(values[scan], depth)
		if key < pivot {
			values[less], values[scan] = values[scan], values[less]
			less++
			scan++
		} else if key > pivot {
			greater--
			values[scan], values[greater] = values[greater], values[scan]
		} else { scan++ }
	}
	mut low := values[..less]
	multikey_sort(mut low, depth)
	if pivot != 0 {
		mut equal := values[less..greater]
		multikey_sort(mut equal, depth + 1)
	}
	mut high := values[greater..]
	multikey_sort(mut high, depth)
}
fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'multikey_quick_sort']
pub fn multikey_quick_sort(input &i32, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_parseable_input_words) { return -1 }
		count_raw := input[0]
		if count_raw < 0 || count_raw > max_strings { return -1 }
		count := int(count_raw)
		mut values := []StringRecord{len: count}
		mut pos := 1
		for i in 0 .. count {
			if pos >= int(length) || input[pos] < 0 || input[pos] > max_string_length { return -1 }
			string_length := int(input[pos]); pos++
			if pos + string_length > int(length) { return -1 }
			values[i].length = string_length
			for j in 0 .. string_length {
				byte := input[pos]; pos++
				if byte < 1 || byte > 127 { return -1 }
				values[i].bytes[j] = u8(byte)
			}
		}
		if pos != int(length) { return -1 }
		bytes := int(length) * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		multikey_sort(mut values, 0)
		mut buffer := [max_output_bytes]u8{}
		mut word := 0
		put_i32_le(mut buffer[0], word * 4, count_raw); word++
		for i in 0 .. count {
			put_i32_le(mut buffer[0], word * 4, i32(values[i].length)); word++
			for j in 0 .. values[i].length { put_i32_le(mut buffer[0], word * 4, i32(values[i].bytes[j])); word++ }
		}
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
