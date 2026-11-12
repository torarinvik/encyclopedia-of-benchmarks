module kahan_summation

@[export: 'kahan_summation']
pub fn kahan_summation(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length > 256 { return -1 }
		for index in 0 .. length {
			value := values[index]
			if value != value || value < -1.0e100 || value > 1.0e100 { return -1 }
		}
		if isnil(output) || capacity < 1 { return -2 }

		mut sum := 0.0
		mut correction := 0.0
		for index in 0 .. length {
			adjusted := values[index] - correction
			next := sum + adjusted
			correction = (next - sum) - adjusted
			sum = next
		}
		output[0] = sum
		return 1
	}
}
