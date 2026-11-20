module lucky_number_sieve

const max_candidates = 2048

@[export: 'lucky_number_sieve']
pub fn lucky_number_sieve(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		mode := input[0]
		bound := input[1]
		if (mode != 0 && mode != 1) || bound < 0 || bound > 4096 { return -1 }

		mut candidates := [max_candidates]i64{}
		mut count := 0
		mut first := i64(1)
		if mode == 1 { first = 2 }
		mut value := first
		for value <= bound {
			candidates[count] = value
			count++
			value += 2
		}

		mut selected := 1
		for selected < count {
			step := int(candidates[selected])
			if step > count { break }
			mut write := 0
			mut rank := 0
			for read in 0 .. count {
				rank++
				if rank % step != 0 {
					candidates[write] = candidates[read]
					write++
				}
			}
			count = write
			selected++
		}

		output_bytes := count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. count {
			bits := u64(candidates[index])
			for byte in 0 .. 8 {
				output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
