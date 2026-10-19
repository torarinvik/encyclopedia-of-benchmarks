module ary3

const max_length = 4096

@[export: 'ary3']
pub fn ary3(length i64, mut output &u8, output_capacity usize) i64 {
	if length < 1 || length > i64(max_length) {
		return -1
	}
	n := int(length)
	mut x := [4096]i32{}
	mut y := [4096]i32{}
	for index in 0 .. n {
		x[index] = i32(index + 1)
		y[index] = 0
	}
	for _ in 0 .. 1000 {
		for index := n - 1; index >= 0; index-- {
			y[index] += x[index]
		}
	}

	mut first := u32(y[0])
	mut last := u32(y[n - 1])
	mut first_reversed := [10]u8{}
	mut first_digit_count := 0
	for {
		first_reversed[first_digit_count] = u8(48 + first % 10)
		first_digit_count++
		first /= 10
		if first == 0 {
			break
		}
	}
	mut reversed := [10]u8{}
	mut digit_count := 0
	for {
		reversed[digit_count] = u8(48 + last % 10)
		digit_count++
		last /= 10
		if last == 0 {
			break
		}
	}
	required := first_digit_count + 2 + digit_count
	if output == nil || output_capacity < required {
		return -2
	}
	unsafe {
		for index in 0 .. first_digit_count {
			output[index] = first_reversed[first_digit_count - index - 1]
		}
		output[first_digit_count] = 32
		for index in 0 .. digit_count {
			output[first_digit_count + 1 + index] = reversed[digit_count - index - 1]
		}
		output[required - 1] = 10
	}
	return i64(required)
}
