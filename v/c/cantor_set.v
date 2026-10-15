module cantor_set

const max_intervals = 64
const scale = u64(1000000)

fn put_cantor_byte(mut output &u8, capacity usize, mut position &int, value u8) bool {
	if usize(*position) >= capacity { return false }
	unsafe { output[*position] = value }
	unsafe { *position = *position + 1 }
	return true
}

fn put_cantor_text(mut output &u8, capacity usize, mut position &int, text string) bool {
	for index in 0 .. text.len {
		if !put_cantor_byte(mut output, capacity, mut position, text[index]) { return false }
	}
	return true
}

fn put_cantor_uint(mut output &u8, capacity usize, mut position &int, value u64) bool {
	mut digits := [20]u8{}
	mut count := 0
	mut remaining := value
	for {
		digits[count] = u8(48 + int(remaining % u64(10)))
		count++
		remaining /= u64(10)
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		if !put_cantor_byte(mut output, capacity, mut position, digits[count]) { return false }
	}
	return true
}

fn put_cantor_fixed(mut output &u8, capacity usize, mut position &int, ticks u64) bool {
	if !put_cantor_uint(mut output, capacity, mut position, ticks / scale) ||
		!put_cantor_byte(mut output, capacity, mut position, 46) { return false }
	mut fraction := ticks % scale
	mut divisor := u64(100000)
	for divisor > 0 {
		digit := u8(48 + int((fraction / divisor) % u64(10)))
		if !put_cantor_byte(mut output, capacity, mut position, digit) { return false }
		fraction %= divisor
		divisor /= u64(10)
	}
	return true
}

@[export: 'cantor_set']
pub fn cantor_set(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 3 || unsafe { values == nil } { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > values[1] || values[1] > 100000 || values[2] < 0 || values[2] > 6 {
			return -1
		}
	}
	if unsafe { output == nil } { return -2 }
	unsafe {
		start := u64(values[0])
		span := u64(values[1] - values[0])
		levels := int(values[2])
		mut positions := [max_intervals]u64{}
		mut next := [max_intervals]u64{}
		mut interval_count := 1
		mut denominator := u64(1)
		mut position := 0
		for level in 0 .. levels + 1 {
			if !put_cantor_text(mut output, output_capacity, mut position, "Level ") ||
				!put_cantor_uint(mut output, output_capacity, mut position, u64(level)) ||
				!put_cantor_byte(mut output, output_capacity, mut position, 9) { return -2 }
			for index in 0 .. interval_count {
				left_numerator := start * denominator + span * positions[index]
				right_numerator := start * denominator + span * (positions[index] + u64(1))
				left := (left_numerator * scale + denominator / u64(2)) / denominator
				right := (right_numerator * scale + denominator / u64(2)) / denominator
				if !put_cantor_text(mut output, output_capacity, mut position, "\t[") ||
					!put_cantor_fixed(mut output, output_capacity, mut position, left) ||
					!put_cantor_text(mut output, output_capacity, mut position, "] -- [") ||
					!put_cantor_fixed(mut output, output_capacity, mut position, right) ||
					!put_cantor_byte(mut output, output_capacity, mut position, 93) { return -2 }
			}
			if !put_cantor_byte(mut output, output_capacity, mut position, 10) { return -2 }
			if level < levels {
				if !put_cantor_byte(mut output, output_capacity, mut position, 10) { return -2 }
				for index in 0 .. interval_count {
					next[2 * index] = positions[index] * u64(3)
					next[2 * index + 1] = positions[index] * u64(3) + u64(2)
				}
				interval_count *= 2
				for index in 0 .. interval_count { positions[index] = next[index] }
				denominator *= u64(3)
			}
		}
		if usize(position) >= output_capacity { return -2 }
		output[position] = 0
		position++
		return i64(position)
	}
}
