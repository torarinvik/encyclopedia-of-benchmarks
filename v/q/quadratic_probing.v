module quadratic_probing

const min_capacity = 5
const max_capacity = 31
const max_insert_count = 3
const max_parseable_input_length = 5
const max_output_bytes = 256

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'quadratic_probing']
pub fn quadratic_probing(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_parseable_input_length) { return -1 }
		capacity_value, count_value := input[0], input[1]
		if capacity_value < min_capacity || capacity_value > max_capacity || count_value < 0 || count_value > max_insert_count { return -1 }
		capacity, insert_count := int(capacity_value), int(count_value)
		if input_length != usize(2 + insert_count) { return -1 }
		for index in 0 .. insert_count {
			if input[index + 2] < 0 { return -1 }
		}

		mut slots := [max_capacity]i64{init: -1}
		for key_index in 0 .. insert_count {
			key := input[key_index + 2]
			home := int(key % i64(capacity))
			if slots[home] == -1 {
				slots[home] = key
				continue
			}
			if slots[home] == key { continue }
			mut visited := [max_capacity]bool{}
			mut probe := 1
			for {
				slot := (home + probe * probe) % capacity
				if slots[slot] == -1 || slots[slot] == i64(home) {
					slots[slot] = key
					break
				}
				if visited[slot] { return -1 }
				visited[slot] = true
				probe++
			}
		}

		byte_length := 8 * (capacity + 1)
		if byte_length > max_output_bytes || output == nil || output_capacity < usize(byte_length) { return -2 }
		put_i64_le(mut output, 0, i64(capacity))
		for index in 0 .. capacity { put_i64_le(mut output, 8 * (index + 1), slots[index]) }
		return i64(byte_length)
	}
}
