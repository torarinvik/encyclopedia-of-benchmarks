module alpha_numerical_sort

fn is_digit(value i64) bool { return value >= 48 && value <= 57 }
fn valid_string(input &i64, start int, count int) bool {
	for i in 0 .. count {
		value := unsafe { input[start + i] }
		if !is_digit(value) && (value < 97 || value > 122) { return false }
		if value == 48 && i > 0 && is_digit(unsafe { input[start + i - 1] }) { return false }
	}
	return true
}

@[export: 'alpha_numerical_sort']
pub fn alpha_numerical_sort(input &i64, length usize) i64 {
	if length < 2 || unsafe { input == nil } { return -2 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -2 }
		first_length := int(input[0])
		if usize(1 + first_length) >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64 { return -2 }
		second_length := int(input[1 + first_length])
		if length != usize(2 + first_length + second_length) || !valid_string(input, 2, first_length) || !valid_string(input, 2 + first_length, second_length) { return -2 }
		mut i := 0
		mut j := 0
		for i < first_length && j < second_length {
			a, b := input[2 + i], input[2 + first_length + j]
			if is_digit(a) && is_digit(b) {
				mut end_a := i
				mut end_b := j
				for end_a < first_length && is_digit(input[2 + end_a]) { end_a++ }
				for end_b < second_length && is_digit(input[2 + first_length + end_b]) { end_b++ }
				digits_a, digits_b := end_a - i, end_b - j
				if digits_a != digits_b { return if digits_a < digits_b { i64(-1) } else { i64(1) } }
				for k in 0 .. digits_a {
					ca, cb := input[2 + i + k], input[2 + first_length + j + k]
					if ca != cb { return if ca < cb { i64(-1) } else { i64(1) } }
				}
				i, j = end_a, end_b
			} else {
				if a != b { return if a < b { i64(-1) } else { i64(1) } }
				i++; j++
			}
		}
		if i == first_length && j == second_length { return 0 }
		if i == first_length { return -1 }
		return 1
	}
}
