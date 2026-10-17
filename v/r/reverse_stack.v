module reverse_stack

const max_elements = 16

fn insert_at_bottom(mut items [16]i64, size int, value i64) {
	if size == 0 { items[0] = value; return }
	top := items[size - 1]
	insert_at_bottom(mut items, size - 1, value)
	items[size] = top
}

fn reverse_recursive(mut items [16]i64, size int) {
	if size == 0 { return }
	top := items[size - 1]
	reverse_recursive(mut items, size - 1)
	insert_at_bottom(mut items, size - 1, top)
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'reverse_stack']
pub fn reverse_stack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_elements || length != usize(raw_count + 1) { return -1 }
		count := int(raw_count)
		mut items := [16]i64{}
		for i in 0 .. count {
			if input[i + 1] < -1_000_000 || input[i + 1] > 1_000_000 { return -1 }
			items[i] = input[i + 1]
		}
		bytes := (count + 1) * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		reverse_recursive(mut items, count)
		put_i64_le(mut output, 0, raw_count)
		for i in 0 .. count { put_i64_le(mut output, 8 * (i + 1), items[i]) }
		return i64(bytes)
	}
}
