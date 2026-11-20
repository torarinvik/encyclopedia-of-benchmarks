module motzkin_number

const max_parseable_length = usize(2)
const max_n = i64(30)

fn motzkin_number_value(n int) i64 {
	mut values := [31]i64{}
	values[0] = 1
	if n >= 1 { values[1] = 1 }
	if n >= 2 {
		for size in 2 .. n + 1 {
			mut total := values[size - 1]
			for left in 0 .. size - 1 {
				total += values[left] * values[size - 2 - left]
			}
			values[size] = total
		}
	}
	return values[n]
}

@[export: 'motzkin_number']
pub fn motzkin_number(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 || input[0] < 0 || input[0] > max_n { return -1 }
		return motzkin_number_value(int(input[0]))
	}
}
