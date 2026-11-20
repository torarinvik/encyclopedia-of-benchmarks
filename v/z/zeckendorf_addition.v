module zeckendorf_addition

const max_bits = 64
const max_parseable = 131
const max_output = 66

fn canonical(bits &i64, length int) bool {
	unsafe {
		if length == 1 && bits[0] == 0 { return true }
		if length == 0 || bits[0] != 1 { return false }
		for i in 0 .. length {
			if bits[i] != 0 && bits[i] != 1 { return false }
			if i + 1 < length && bits[i] == 1 && bits[i + 1] == 1 { return false }
		}
	}
	return true
}

fn stage_one(mut d [max_output]u8, n int) {
	if n >= 4 {
		for i in 0 .. n - 3 {
			if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0 {
				d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] += 1
			} else if d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0 {
				d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] += 1
			} else if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1 {
				d[i] = 1; d[i + 1] = 1; d[i + 2] = 0
			} else if d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2 {
				d[i] = 1; d[i + 1] = 0; d[i + 2] = 1
			}
		}
	}
	if n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0 {
		d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0 {
		d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
	} else if n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0 {
		d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1 {
		d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0
	}
	if n >= 2 && d[n - 2] == 0 && d[n - 1] == 3 {
		d[n - 2] = 1; d[n - 1] = 1
	} else if n >= 2 && d[n - 2] == 0 && d[n - 1] == 2 {
		d[n - 2] = 1; d[n - 1] = 0
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2 {
		d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
	}
}

@[export: 'zeckendorf_addition']
pub fn zeckendorf_addition(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_parseable { return -1 }
		first_n_value := input[0]
		if first_n_value < 1 || first_n_value > max_bits { return -1 }
		first_n := int(first_n_value)
		second_n_index := first_n + 1
		if usize(second_n_index) >= length { return -1 }
		second_n_value := input[second_n_index]
		if second_n_value < 1 || second_n_value > max_bits { return -1 }
		second_n := int(second_n_value)
		if int(length) != second_n_index + second_n + 1 { return -1 }
		first := &input[1]
		second := &input[second_n_index + 1]
		if !canonical(first, first_n) || !canonical(second, second_n) { return -1 }
		width := if first_n > second_n { first_n } else { second_n }
		first_offset := width - first_n
		second_offset := width - second_n
		mut digits := [max_output]u8{}
		digit_count := width + 1
		for i in 0 .. width {
			a := if i < first_offset { u8(0) } else { u8(first[i - first_offset]) }
			b := if i < second_offset { u8(0) } else { u8(second[i - second_offset]) }
			digits[i + 1] = a + b
		}
		stage_one(mut digits, digit_count)
		for i := digit_count; i > 0; i-- { digits[i] = digits[i - 1] }
		digits[0] = 0
		digit_count++
		for i := digit_count - 2; i > 0; i-- {
			start := i - 1
			if digits[start] == 0 && digits[start + 1] == 1 && digits[start + 2] == 1 {
				digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0
			}
		}
		for i in 0 .. digit_count - 2 {
			if digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1 {
				digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0
			}
		}
		mut first_output := 0
		for first_output + 1 < digit_count && digits[first_output] == 0 { first_output++ }
		required := digit_count - first_output
		if output == nil || output_capacity < usize(required) { return -2 }
		for i in 0 .. required { output[i] = u8('0') + digits[first_output + i] }
		return i64(required)
	}
}
