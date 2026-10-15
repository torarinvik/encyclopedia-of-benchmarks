module hamming_numbers

const max_count = 32

@[export: 'hamming_numbers']
pub fn hamming_numbers(input &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 1 || count_value > max_count { return -1 }
	count := int(count_value)
	output_bytes := count * 8
	if output_capacity < usize(output_bytes) { return -2 }

	mut values := [32]u64{}
	values[0] = 1
	mut i2 := 0
	mut i3 := 0
	mut i5 := 0
	for index := 1; index < count; index++ {
		c2 := values[i2] * 2
		c3 := values[i3] * 3
		c5 := values[i5] * 5
		mut next := if c2 < c3 { c2 } else { c3 }
		if c5 < next { next = c5 }
		values[index] = next
		if c2 == next { i2++ }
		if c3 == next { i3++ }
		if c5 == next { i5++ }
	}
	for index in 0 .. count {
		for byte in 0 .. 8 {
			unsafe { output[index * 8 + byte] = u8(values[index] >> (byte * 8)) }
		}
	}
	return i64(count)
}
