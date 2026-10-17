const max_intervals = 256
const max_input_length = 1 + 2 * max_intervals

fn store_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'merge_intervals']
pub fn merge_intervals(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_input_length) { return -1 }
		raw_count := values[0]
		if raw_count < 0 || raw_count > max_intervals { return -1 }
		count := int(raw_count)
		if length != usize(1 + 2 * count) { return -1 }

		mut starts := [max_intervals]i64{init: 0}
		mut ends := [max_intervals]i64{init: 0}
		for index := 0; index < count; index++ {
			start := values[1 + 2 * index]
			ending := values[2 + 2 * index]
			if start < -2147483648 || start > 2147483647 ||
				ending < -2147483648 || ending > 2147483647 || start > ending { return -1 }
			starts[index] = start
			ends[index] = ending
		}

		for index := 1; index < count; index++ {
			start := starts[index]
			ending := ends[index]
			mut position := index
			for position > 0 && starts[position - 1] > start {
				starts[position] = starts[position - 1]
				ends[position] = ends[position - 1]
				position--
			}
			starts[position] = start
			ends[position] = ending
		}

		mut merged := 0
		for index := 0; index < count; index++ {
			if merged > 0 && starts[index] <= ends[merged - 1] {
				if ends[index] > ends[merged - 1] { ends[merged - 1] = ends[index] }
			} else {
				starts[merged] = starts[index]
				ends[merged] = ends[index]
				merged++
			}
		}

		byte_count := 8 * merged
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for index := 0; index < merged; index++ {
			store_i32_le(output, index * 8, starts[index])
			store_i32_le(output, index * 8 + 4, ends[index])
		}
		return i64(byte_count)
	}
}
