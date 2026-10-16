module excess_3_code

@[export: 'excess_3_code']
pub fn excess_3_code(value i64, output &u8, output_capacity usize) i64 {
	mut number := u64(0)
	if value >= 0 { number = u64(value) }
	mut digits := [19]u8{}
	mut count := 0
	for number > 0 {
		digits[count] = u8(number % 10)
		count++
		number /= 10
	}
	if count == 0 { digits[0] = 0; count = 1 }
	output_length := 2 + 4 * count
	if output_capacity < output_length { return -2 }
	unsafe {
		output[0] = u8(`0`)
		output[1] = u8(`b`)
	}
	mut position := 2
	for count > 0 {
		count--
		nibble := int(digits[count]) + 3
		for bit in 0 .. 4 {
			if nibble & (1 << (3 - bit)) != 0 {
				unsafe { output[position] = u8(`1`) }
			} else {
				unsafe { output[position] = u8(`0`) }
			}
			position++
		}
	}
	return i64(output_length)
}
