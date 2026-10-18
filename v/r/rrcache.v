module rrcache

const max_operations = 32
const max_input_length = 3 + 3 * max_operations
const max_output_bytes = 8 * max_operations
const java_multiplier = u64(0x5deece66d)
const java_addend = u64(0xb)
const java_mask = (u64(1) << 48) - 1

fn java_next_bits(mut state &u64, bits u32) u32 {
	unsafe {
		state[0] = (state[0] *% java_multiplier +% java_addend) & java_mask
		return u32(state[0] >> (48 - bits))
	}
}

fn java_next_int(mut state &u64, bound u32) u32 {
	if (bound & (bound - 1)) == 0 {
		return u32((u64(bound) * u64(java_next_bits(mut state, 31))) >> 31)
	}
	for {
		bits := java_next_bits(mut state, 31)
		value := bits % bound
		if u64(bits) - u64(value) + u64(bound - 1) <= u64(0x7fffffff) { return value }
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'rrcache']
pub fn rrcache(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > 8 || input[2] < 0 || input[2] > max_operations { return -1 }
		cache_capacity := int(input[0])
		operation_count := int(input[2])
		if int(length) != 3 + 3 * operation_count { return -1 }

		mut keys := [8]i64{}
		mut values := [8]i64{}
		mut results := [max_operations]i64{}
		mut size := 0
		mut random_state := (u64(input[1]) ^ java_multiplier) & java_mask

		for operation in 0 .. operation_count {
			offset := 3 + 3 * operation
			opcode := input[offset]
			key := input[offset + 1]
			value := input[offset + 2]
			if opcode == 0 {
				if key < 1 || key > 1024 || value < 100 || value > 1_000_000 { return -1 }
				mut index := 0
				for index < size && keys[index] != key { index++ }
				if index < size {
					values[index] = value
				} else {
					if size == cache_capacity {
						evicted := int(java_next_int(mut random_state, u32(size)))
						for move := evicted; move + 1 < size; move++ {
							keys[move] = keys[move + 1]
							values[move] = values[move + 1]
						}
						size--
					}
					keys[size] = key
					values[size] = value
					size++
				}
				results[operation] = -2
			} else if opcode == 1 {
				if key < 1 || key > 1024 || value != 0 { return -1 }
				mut index := 0
				for index < size && keys[index] != key { index++ }
				results[operation] = if index < size { values[index] } else { -1 }
			} else if opcode == 2 {
				if key != 0 || value != 0 { return -1 }
				results[operation] = i64(size)
			} else {
				return -1
			}
		}

		output_bytes := operation_count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for operation in 0 .. operation_count { put_i64_le(mut staged[0], operation * 8, results[operation]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
