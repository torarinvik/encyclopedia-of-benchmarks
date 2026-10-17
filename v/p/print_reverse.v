module print_reverse

const max_values = 256
const max_parseable_input_length = max_values + 2
const max_output_bytes = 3836
const i32_min_value = i64(-2147483648)
const i32_max_value = i64(2147483647)

@[export: 'print_reverse']
pub fn print_reverse(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_parseable_input_length || length > max_values { return -1 }
	unsafe {
		if length > 0 && values == nil { return -1 }
		for index in 0 .. int(length) {
			value := values[index]
			if value < i32_min_value || value > i32_max_value { return -1 }
		}

		mut encoded := []u8{len: max_output_bytes}
		mut written := 0
		mut remaining := int(length)
		for remaining > 0 {
			remaining--
			if written > 0 {
				encoded[written] = 32
				encoded[written + 1] = 60
				encoded[written + 2] = 45
				encoded[written + 3] = 32
				written += 4
			}
			value := values[remaining]
			mut magnitude := u64(0)
			if value < 0 {
				encoded[written] = 45
				written++
				magnitude = u64(-value)
			} else {
				magnitude = u64(value)
			}
			mut digits := []u8{len: 10}
			mut count := 0
			for {
				digits[count] = u8(48 + magnitude % 10)
				count++
				magnitude /= 10
				if magnitude == 0 { break }
			}
			for count > 0 {
				count--
				encoded[written] = digits[count]
				written++
			}
		}

		if output == nil || output_capacity < usize(written) { return -2 }
		for index in 0 .. written { output[index] = encoded[index] }
		return i64(written)
	}
}
