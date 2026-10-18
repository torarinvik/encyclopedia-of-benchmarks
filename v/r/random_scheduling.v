const max_task_count = 32
const max_input_length = 35
const max_output_bytes = 256
const java_multiplier = u64(0x5deece66d)
const java_addend = u64(0xb)
const java_mask = u64(0xffffffffffff)

struct JavaRandom {
	mut:
	state u64
}

fn java_next_bits(mut random JavaRandom, bits u32) u32 {
	random.state = (random.state * java_multiplier + java_addend) & java_mask
	return u32(random.state >> (48 - bits))
}

fn java_next_int(mut random JavaRandom, bound u32) u32 {
	if (bound & (bound - 1)) == 0 {
		return u32((u64(bound) * u64(java_next_bits(mut random, 31))) >> 31)
	}
	for {
		bits := java_next_bits(mut random, 31)
		value := bits % bound
		if u64(bits) - u64(value) + u64(bound - 1) <= u64(2147483647) { return value }
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'random_scheduling']
pub fn random_scheduling(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		if input[1] < 0 || input[1] > max_task_count { return -1 }
		count := int(input[1])
		if input_length != usize(count + 2) { return -1 }
		mut tasks := [max_task_count]i64{}
		for index in 0 .. count {
			task := input[index + 2]
			if task < -2147483648 || task > 2147483647 { return -1 }
			tasks[index] = task
		}
		mut random := JavaRandom{state: (u64(input[0]) ^ java_multiplier) & java_mask}
		for size := count; size > 1; size-- {
			selected := int(java_next_int(mut random, u32(size)))
			saved := tasks[size - 1]
			tasks[size - 1] = tasks[selected]
			tasks[selected] = saved
		}

		output_bytes := count * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. count { put_i64_le(mut output, index * 8, tasks[index]) }
		return i64(output_bytes)
	}
}
