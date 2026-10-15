module array_keys_sort

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}
fn compare_rows(left []i64, right []i64, keys []int, ascending bool) int {
	for field in keys {
		a, b := left[field - 1], right[field - 1]
		if a < b { return if ascending { -1 } else { 1 } }
		if a > b { return if ascending { 1 } else { -1 } }
	}
	return 0
}
@[export: 'array_keys_sort']
pub fn array_keys_sort(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 8 || length > 263 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_count, raw_key_count, order := values[0], values[1], values[2]
		if raw_count < 1 || raw_count > 64 || raw_key_count < 1 || raw_key_count > 4 || (order != 0 && order != 1) { return -1 }
		count, key_count := int(raw_count), int(raw_key_count)
		if length != usize(3 + key_count + 4 * count) { return -1 }
		mut keys := []int{len: key_count, init: 0}
		for index in 0 .. key_count {
			key := int(values[index + 3])
			if key < 1 || key > 4 { return -1 }
			for previous in 0 .. index { if keys[previous] == key { return -1 } }
			keys[index] = key
		}
		mut rows := []i64{len: count * 4, init: 0}
		rows_start := 3 + key_count
		for index in 0 .. count * 4 {
			value := values[rows_start + index]
			if value < -1000 || value > 1000 { return -1 }
			rows[index] = value
		}
		for left in 0 .. count {
			for right in left + 1 .. count {
				if compare_rows(rows[left * 4 .. left * 4 + 4], rows[right * 4 .. right * 4 + 4], keys, true) == 0 { return -1 }
			}
		}
		byte_count := 32 * count
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for index in 1 .. count {
			mut temporary := []i64{len: 4, init: 0}
			for column in 0 .. 4 { temporary[column] = rows[index * 4 + column] }
			mut position := index
			for position > 0 && compare_rows(rows[(position - 1) * 4 .. position * 4], temporary, keys, order == 1) > 0 {
				for column in 0 .. 4 { rows[position * 4 + column] = rows[(position - 1) * 4 + column] }
				position--
			}
			for column in 0 .. 4 { rows[position * 4 + column] = temporary[column] }
		}
		for index in 0 .. count * 4 { store_i64_le(mut output, 8 * index, rows[index]) }
		return i64(byte_count)
	}
}
