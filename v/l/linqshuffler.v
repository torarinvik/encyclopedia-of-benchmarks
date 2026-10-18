module linqshuffler

const max_n = 64
const max_parseable_input_length = 67
const max_output_bytes = 520
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)
const mbig = i64(2147483647)

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'linqshuffler']
pub fn linqshuffler(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_parseable_input_length { return -1 }
		n_value := input[0]
		seed := input[1]
		if n_value < 0 || n_value > max_n || seed < i32_min || seed > i32_max { return -1 }
		n := int(n_value)
		if input_length != usize(n + 2) { return -1 }

		mut values := [max_n]i64{}
		mut keys := [max_n]i64{}
		for index in 0 .. n {
			value := input[index + 2]
			if value < i32_min || value > i32_max { return -1 }
			values[index] = value
		}

		subtraction := if seed == i32_min { i32_max } else { if seed < 0 { -seed } else { seed } }
		mut seed_array := [56]i64{}
		mut mj := i64(161803398) - subtraction
		seed_array[55] = mj
		mut mk := i64(1)
		for i in 1 .. 55 {
			ii := (21 * i) % 55
			seed_array[ii] = mk
			mk = mj - mk
			if mk < 0 { mk += mbig }
			mj = seed_array[ii]
		}
		for _ in 0 .. 4 {
			for i in 1 .. 56 {
				offset_index := 1 + (i + 30) % 55
				seed_array[i] -= seed_array[offset_index]
				if seed_array[i] < 0 { seed_array[i] += mbig }
			}
		}

		mut inext := 0
		mut inextp := 21
		for index in 0 .. n {
			inext++
			if inext >= 56 { inext = 1 }
			inextp++
			if inextp >= 56 { inextp = 1 }
			mut sample := seed_array[inext] - seed_array[inextp]
			if sample == mbig { sample-- }
			if sample < 0 { sample += mbig }
			seed_array[inext] = sample
			keys[index] = sample
		}

		// Strict comparison preserves input order for equal random keys.
		for index := 1; index < n; index++ {
			key := keys[index]
			value := values[index]
			mut cursor := index
			for cursor > 0 && keys[cursor - 1] > key {
				keys[cursor] = keys[cursor - 1]
				values[cursor] = values[cursor - 1]
				cursor--
			}
			keys[cursor] = key
			values[cursor] = value
		}

		output_bytes := 8 * (n + 1)
		if output_bytes > max_output_bytes || output == nil || output_capacity < usize(output_bytes) { return -2 }
		store_i64_le(output, 0, n_value)
		for index in 0 .. n { store_i64_le(output, 8 * (index + 1), values[index]) }
		return i64(output_bytes)
	}
}
