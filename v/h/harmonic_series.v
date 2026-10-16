module harmonic_series

@[export: 'harmonic_series']
pub fn harmonic_series(n i64, output &u8, capacity usize) i64 {
	if n < -512 || n > 512 { return -1 }
	if n <= 0 { return 0 }
	mut needed := 2
	for term in 2 .. int(n) + 1 {
		mut value := term
		mut digits := 0
		for {
			digits++
			value /= 10
			if value == 0 { break }
		}
		needed += digits + 3
	}
	if capacity < usize(needed) { return -2 }
	unsafe {
		mut position := 0
		output[position] = u8(`1`); position++
		output[position] = 10; position++
		for term in 2 .. int(n) + 1 {
			output[position] = u8(`1`); position++
			output[position] = u8(`/`); position++
			mut digits := [4]u8{}
			mut value := term
			mut count := 0
			for {
				digits[count] = u8(`0` + value % 10)
				count++
				value /= 10
				if value == 0 { break }
			}
			for count > 0 {
				count--
				output[position] = digits[count]
				position++
			}
			output[position] = 10; position++
		}
		return i64(position)
	}
}
