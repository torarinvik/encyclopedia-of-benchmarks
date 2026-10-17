module permute_string

const max_n = 7
const max_input_length = 9

fn factorial(value int) int {
	if value < 2 { return 1 }
	mut result := 1
	for factor in 2 .. value + 1 { result *= factor }
	return result
}

fn unique_permutation_count(values &u8, length int) int {
	if length == 0 { return 0 }
	mut frequencies := [128]int{}
	for index in 0 .. length {
		frequencies[int(unsafe { values[index] })]++
	}
	mut count := factorial(length)
	for frequency in frequencies { count /= factorial(frequency) }
	return count
}

fn next_permutation(values &u8, length int) bool {
	if length < 2 { return false }
	mut pivot := length - 1
	for pivot > 0 && unsafe { values[pivot - 1] >= values[pivot] } { pivot-- }
	if pivot == 0 { return false }
	mut successor := length - 1
	for unsafe { values[successor] <= values[pivot - 1] } { successor-- }
	unsafe {
		values[pivot - 1], values[successor] = values[successor], values[pivot - 1]
		mut left := pivot
		mut right := length - 1
		for left < right {
			values[left], values[right] = values[right], values[left]
			left++
			right--
		}
	}
	return true
}

@[export: 'permute_string']
pub fn permute_string(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_n { return -1 }
		character_count := int(input[0])
		if input_length != usize(character_count + 1) { return -1 }

		mut values := [max_n]u8{}
		for index := 0; index < character_count; index++ {
			value := input[index + 1]
			if value < 0 || value > 127 { return -1 }
			values[index] = u8(value)
		}
		values[..character_count].sort()
		permutation_count := unique_permutation_count(&values[0], character_count)
		output_bytes := permutation_count * character_count
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for row := 0; row < permutation_count; row++ {
			for column := 0; column < character_count; column++ {
				output[row * character_count + column] = values[column]
			}
			if row + 1 < permutation_count {
				_ = next_permutation(&values[0], character_count)
			}
		}
		return i64(output_bytes)
	}
}
