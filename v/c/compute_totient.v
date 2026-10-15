module compute_totient

fn decimal_length(value i64) usize {
	mut remaining := value
	mut length := usize(1)
	for remaining >= 10 {
		remaining /= 10
		length++
	}
	return length
}

fn append_decimal(value_input i64, output &u8, position_input usize) usize {
	mut digits := [3]u8{}
	mut count := usize(0)
	mut value := value_input
	for {
		digits[count] = u8(value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	mut position := position_input
	for count > 0 {
		count--
		unsafe { output[position] = u8(`0`) + digits[count] }
		position++
	}
	return position
}

@[export: 'compute_totient']
pub fn compute_totient(n i64, output &u8, output_capacity usize) i64 {
	if n < 1 || n > 80 { return -1 }
	mut phi := [80]i64{}
	for i in 1 .. n + 1 { phi[i - 1] = i }
	for p in 2 .. n + 1 {
		if phi[p - 1] != p { continue }
		phi[p - 1] = p - 1
		mut i := 2 * p
		for i <= n {
			phi[i - 1] = (phi[i - 1] / p) * (p - 1)
			i += p
		}
	}
	mut required := usize(n - 1)
	for i in 0 .. n { required += decimal_length(phi[i]) }
	if output_capacity < required { return -2 }
	mut position := usize(0)
	for i in 0 .. n {
		if i > 0 {
			unsafe { output[position] = u8(`,`) }
			position++
		}
		position = append_decimal(phi[i], output, position)
	}
	return i64(position)
}
