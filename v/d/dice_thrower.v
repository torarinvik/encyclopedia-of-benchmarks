module dice_thrower

const max_target = 8

fn required_bytes(remaining int, depth int) int {
	if remaining == 0 { return depth + 1 }
	mut total := 0
	maximum_face := if remaining < 6 { remaining } else { 6 }
	for face in 1 .. maximum_face + 1 {
		total += required_bytes(remaining - face, depth + 1)
	}
	return total
}

fn emit_combinations(remaining int, depth int, mut digits [8]u8, output &u8, mut position int) {
	if remaining == 0 {
		for index in 0 .. depth {
			unsafe { output[position] = digits[index] }
			position++
		}
		unsafe { output[position] = u8(10) }
		position++
		return
	}
	maximum_face := if remaining < 6 { remaining } else { 6 }
	for face in 1 .. maximum_face + 1 {
		digits[depth] = u8(`0` + face)
		emit_combinations(remaining - face, depth + 1, mut digits, output, mut position)
	}
}

@[export: 'dice_thrower']
pub fn dice_thrower(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != 1 { return -1 }
	target_value := unsafe { values[0] }
	if target_value < 0 || target_value > max_target { return -1 }
	target := int(target_value)
	needed := required_bytes(target, 0)
	if unsafe { output == nil } || output_capacity < usize(needed) { return -2 }
	mut digits := [8]u8{}
	mut position := 0
	emit_combinations(target, 0, mut digits, output, mut position)
	return i64(position)
}
