module choiceset

const max_operations = 1024
const max_elements = 256
const hash_capacity = 512
const max_key = 1_000_000_000

fn hash_slot(value i32) int {
	bits := u32(value)
	mixed := u64(bits) * u64(2654435761)
	return int(u32(mixed) >> 23)
}

fn find_slot(keys &i32, states &u8, value i32) int {
	mut slot := hash_slot(value)
	mut deleted := hash_capacity
	unsafe {
		for _ in 0 .. hash_capacity {
			if states[slot] == 0 { return if deleted < hash_capacity { deleted } else { slot } }
			if states[slot] == 2 {
				if deleted == hash_capacity { deleted = slot }
			} else if keys[slot] == value { return slot }
			slot = (slot + 1) % hash_capacity
		}
	}
	return deleted
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'choiceset']
pub fn choiceset(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || values[0] < 0 || values[0] > max_operations { return -1 }
		operation_count := int(values[0])
		if length != usize(1 + 2 * operation_count) { return -1 }
		output_bytes := operation_count * 8

		mut elements := [max_elements]i32{}
		mut map_keys := [hash_capacity]i32{}
		mut map_indices := [hash_capacity]int{}
		mut states := [hash_capacity]u8{}
		mut results := [max_operations]i64{}
		mut element_count := 0
		for operation_index in 0 .. operation_count {
			operation := values[1 + 2 * operation_index]
			argument := values[2 + 2 * operation_index]
			if operation >= 1 && operation <= 3 {
				if argument < -max_key || argument > max_key { return -1 }
				key := i32(argument)
				slot := find_slot(&map_keys[0], &states[0], key)
				found := states[slot] == 1 && map_keys[slot] == key
				if operation == 1 {
					if found { results[operation_index] = 0 } else {
						if element_count == max_elements || slot >= hash_capacity { return -1 }
						elements[element_count] = key
						map_keys[slot] = key
						map_indices[slot] = element_count
						states[slot] = 1
						element_count++
						results[operation_index] = 1
					}
				} else if operation == 2 {
					results[operation_index] = if found { 1 } else { 0 }
				} else if !found {
					results[operation_index] = 0
				} else {
					index := map_indices[slot]
					last := element_count - 1
					if index != last {
						moved := elements[last]
						moved_slot := find_slot(&map_keys[0], &states[0], moved)
						if states[moved_slot] != 1 || map_keys[moved_slot] != moved { return -1 }
						elements[index] = moved
						map_indices[moved_slot] = index
					}
					element_count--
					states[slot] = 2
					results[operation_index] = 1
				}
			} else if operation == 4 {
				if argument < 1 || argument > i64(element_count) { return -1 }
				results[operation_index] = i64(elements[int(argument) - 1])
			} else { return -1 }
		}
		if capacity < usize(output_bytes) || (output_bytes > 0 && output == nil) { return -2 }
		for index in 0 .. operation_count { put_i64_le(mut output, index * 8, results[index]) }
		return i64(output_bytes)
	}
}
