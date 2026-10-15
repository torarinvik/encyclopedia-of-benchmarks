module euler_totient_sequence

fn decimal_length(value i64) usize {
	mut remaining := value
	mut length := usize(1)
	for remaining >= 10 { remaining /= 10; length++ }
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

@[export: 'euler_totient_sequence']
pub fn euler_totient_sequence(n i64, output &u8, output_capacity usize) i64 {
	if n < 1 || n > 80 { return -1 }
	mut phi := [81]i64{}
	for value in 1 .. n + 1 {
		mut remaining := value
		mut totient := value
		mut p := i64(2)
		for p * p <= remaining {
			if remaining % p == 0 {
				for remaining % p == 0 { remaining /= p }
				totient -= totient / p
			}
			p++
		}
		if remaining > 1 { totient -= totient / remaining }
		phi[value] = totient
	}
	mut required := usize(n - 1)
	for i in 1 .. n + 1 { required += decimal_length(phi[i]) }
	if output_capacity < required { return -2 }
	mut position := usize(0)
	for i in 1 .. n + 1 {
		if i > 1 {
			unsafe { output[position] = u8(`,`) }
			position++
		}
		position = append_decimal(phi[i], output, position)
	}
	return i64(position)
}
