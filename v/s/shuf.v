module shuf

const max_input_length = 67

fn write_i32_le(mut output &u8, index int, value i32) {
	unsafe {
		bits := u32(value)
		offset := index * 4
		for byte in 0 .. 4 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'shuf']
pub fn shuf(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		count_raw, sample_size_raw := input[0], input[1]
		if count_raw < 0 || count_raw > 32 || sample_size_raw < 1 || sample_size_raw > 32 { return -1 }
		count, sample_size := int(count_raw), int(sample_size_raw)
		if int(length) != 2 + 2 * count { return -1 }

		mut items := [32]i32{}
		mut sample := [32]i32{}
		mut occupied := [32]bool{}
		for index in 0 .. count {
			value := input[2 + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			items[index] = i32(value)
		}
		initial_count := if count < sample_size { count } else { sample_size }
		for index in 0 .. initial_count {
			draw := input[2 + count + index]
			if draw < 0 || draw >= i64(sample_size) { return -1 }
			mut slot := int(draw)
			for occupied[slot] {
				slot++
				if slot == sample_size { slot = 0 }
			}
			sample[slot] = items[index]
			occupied[slot] = true
		}
		if count >= sample_size {
			for index in sample_size .. count {
				draw := input[2 + count + index]
				if draw < 0 || draw > i64(index) { return -1 }
				if draw < i64(sample_size) { sample[int(draw)] = items[index] }
			}
		}

		output_bytes := initial_count * 4
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut output_count := 0
		for slot in 0 .. sample_size {
			if occupied[slot] {
				write_i32_le(mut output, output_count, sample[slot])
				output_count++
			}
		}
		return i64(output_count)
	}
}
