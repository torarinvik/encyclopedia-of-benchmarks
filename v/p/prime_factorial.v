module prime_factorial

fn is_prime_by_source_trial_division(candidate i64) bool {
	if candidate == 2 { return true }
	half_candidate := candidate / 2 + 1
	mut divisor := i64(2)
	for divisor <= half_candidate {
		if candidate % divisor == 0 { return false }
		if divisor == half_candidate { return true }
		divisor++
	}
	return false
}

@[export: 'prime_factorial']
pub fn prime_factorial(value i64, output &u8, output_capacity usize) i64 {
	if value < 2 || value > 4096 { return -1 }
	mut factors := [5]u32{}
	mut count := 0
	mut candidate := i64(2)
	for candidate <= value {
		if is_prime_by_source_trial_division(candidate) && value % candidate == 0 {
			factors[count] = u32(candidate)
			count++
		}
		candidate++
	}
	if output_capacity < usize(count * 4) { return -2 }
	if unsafe { output == nil } { return -2 }
	mut position := usize(0)
	for index := 0; index < count; index++ {
		mut factor := factors[index]
		for _ in 0 .. 4 {
			unsafe { output[position] = u8(factor & 0xFF) }
			factor >>= 8
			position++
		}
	}
	return i64(position)
}
