module z_algorithm

const max_length = 2047

@[export: 'z_algorithm']
pub fn z_algorithm(input &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 1 || length > 2048 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_length { return -1 }
	count := int(count_value)
	if length != usize(count + 1) { return -1 }
	output_bytes := count * 4
	if output_capacity < usize(output_bytes) { return -2 }

	mut z := [2047]int{}
	mut left := 0
	mut right := 0
	for index := 1; index < count; index++ {
		if index < right { z[index] = if z[index - left] < right - index { z[index - left] } else { right - index } }
		for index + z[index] < count && unsafe { input[1 + z[index]] == input[1 + index + z[index]] } { z[index]++ }
		if index + z[index] > right {
			left = index
			right = index + z[index]
		}
	}
	for index in 0 .. count {
		value := u32(z[index])
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8(value >> (byte * 8)) }
		}
	}
	return i64(count)
}
