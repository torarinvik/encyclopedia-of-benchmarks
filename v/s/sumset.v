module sumset

const min_sum = i64(-2000)
const sum_count = 4001
const max_set_size = i64(64)

fn decimal_width(value_input i64) int {
	mut value := value_input
	mut width := 1
	if value < 0 { value = -value; width++ }
	for value >= 10 { value /= 10; width++ }
	return width
}

fn append_signed_decimal(output &u8, position_input int, value_input i64) int {
	mut value := value_input
	mut position := position_input
	if value < 0 {
		unsafe { output[position] = u8(`-`) }
		position++
		value = -value
	}
	mut digits := [20]u8{}
	mut count := 0
	for {
		digits[count] = u8(value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	unsafe {
		for count > 0 {
			count--
			output[position] = u8(`0`) + digits[count]
			position++
		}
	}
	return position
}

@[export: 'sumset']
pub fn sumset(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	count_a := unsafe { values[0] }
	count_b := unsafe { values[1] }
	if count_a < 0 || count_a > max_set_size || count_b < 0 || count_b > max_set_size ||
		length != usize(2 + count_a + count_b) { return -1 }
	mut present := [sum_count]bool{}
	for index_a in 0 .. int(count_a) {
		left := unsafe { values[index_a + 2] }
		if left < -1000 || left > 1000 { return -1 }
	}
	for index_b in 0 .. int(count_b) {
		right := unsafe { values[int(count_a) + index_b + 2] }
		if right < -1000 || right > 1000 { return -1 }
	}
	for index_a in 0 .. int(count_a) {
		left := unsafe { values[index_a + 2] }
		for index_b in 0 .. int(count_b) {
			right := unsafe { values[int(count_a) + index_b + 2] }
			present[int(left + right - min_sum)] = true
		}
	}
	mut needed := 0
	for index in 0 .. sum_count {
		if present[index] { needed += decimal_width(i64(index) + min_sum) + 1 }
	}
	if needed == 0 { return 0 }
	if output_capacity < usize(needed) { return -2 }
	mut position := 0
	unsafe {
		for index in 0 .. sum_count {
			if !present[index] { continue }
			position = append_signed_decimal(output, position, i64(index) + min_sum)
			output[position] = 10
			position++
		}
	}
	return i64(position)
}
