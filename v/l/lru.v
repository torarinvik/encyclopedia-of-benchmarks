module lru

const max_input_length = 99
const max_operations = 32
const max_capacity = 16
const max_output_fields = 114

fn append(mut records &i64, mut count &int, value i64) {
	unsafe { records[count] = value }
	count++
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'lru']
pub fn lru(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		cache_capacity := input[0]
		operation_count := input[1]
		if cache_capacity < 2 || cache_capacity > i64(max_capacity) || operation_count < 0 || operation_count > i64(max_operations) || int(length) != 2 + 3 * int(operation_count) { return -1 }
		mut keys := [max_capacity]i64{}
		mut values := [max_capacity]i64{}
		mut seen := [max_operations]i64{}
		mut order := [max_capacity]int{}
		mut records := [max_output_fields]i64{}
		mut cache_count := 0
		mut seen_count := 0
		mut record_count := 0
		mut cursor := 2
		for _ in 0 .. int(operation_count) {
			opcode, key, value := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if key < -1000000 || key > 1000000 { return -1 }
			if opcode == 0 {
				if value < -1000000 || value > 1000000 { return -1 }
				for index in 0 .. seen_count { if seen[index] == key { return -1 } }
				seen[seen_count] = key
				seen_count++
				mut slot := cache_count
				if cache_count == int(cache_capacity) {
					slot = order[0]
					for index in 0 .. cache_count - 1 { order[index] = order[index + 1] }
					cache_count--
				}
				keys[slot] = key
				values[slot] = value
				order[cache_count] = slot
				cache_count++
				append(mut records[0], mut record_count, 0)
				append(mut records[0], mut record_count, 0)
			} else if opcode == 1 {
				if value != 0 { return -1 }
				mut position := 0
				for position < cache_count && keys[order[position]] != key { position++ }
				if position == cache_count { return -1 }
				slot := order[position]
				cached_value := values[slot]
				for index in position .. cache_count - 1 { order[index] = order[index + 1] }
				order[cache_count - 1] = slot
				append(mut records[0], mut record_count, 1)
				append(mut records[0], mut record_count, 1)
				append(mut records[0], mut record_count, cached_value)
			} else {
				return -1
			}
		}
		append(mut records[0], mut record_count, 2)
		append(mut records[0], mut record_count, i64(cache_count))
		for index in 0 .. cache_count {
			slot := order[index]
			append(mut records[0], mut record_count, keys[slot])
			append(mut records[0], mut record_count, values[slot])
		}
		output_bytes := record_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. record_count { write_i64_le(mut output, index * 8, records[index]) }
		return i64(output_bytes)
	}
}
