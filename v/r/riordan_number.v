module riordan_number

const max_parseable_length = usize(2)
const max_n = i64(30)

fn riordan_number_value(n int) i64 {
	mut values := [31]i64{}
	values[0] = 1
	for size in 2 .. n + 1 {
		values[size] = i64(size - 1) * (2 * values[size - 1] + 3 * values[size - 2]) / i64(size + 1)
	}
	return values[n]
}

@[export: 'riordan_number']
pub fn riordan_number(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 || input[0] < 0 || input[0] > max_n { return -1 }
		return riordan_number_value(int(input[0]))
	}
}
