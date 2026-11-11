module benchmarkgame_recursive

const max_n = 10
const max_output_bytes = 89

fn ackermann_value(x i64, y i64) i64 {
	if x == 0 { return y + 1 }
	return ackermann_value(x - 1, if y == 0 { i64(1) } else { ackermann_value(x, y - 1) })
}

fn fibonacci_integer(n i64) i64 {
	if n < 2 { return 1 }
	return fibonacci_integer(n - 2) + fibonacci_integer(n - 1)
}

fn fibonacci_float(n f64) f64 {
	if n < 2.0 { return 1.0 }
	return fibonacci_float(n - 2.0) + fibonacci_float(n - 1.0)
}

fn takeuchi_integer(x i64, y i64, z i64) i64 {
	if y < x {
		return takeuchi_integer(takeuchi_integer(x - 1, y, z),
			takeuchi_integer(y - 1, z, x), takeuchi_integer(z - 1, x, y))
	}
	return z
}

fn takeuchi_float(x f64, y f64, z f64) f64 {
	if y < x {
		return takeuchi_float(takeuchi_float(x - 1.0, y, z),
			takeuchi_float(y - 1.0, z, x), takeuchi_float(z - 1.0, x, y))
	}
	return z
}

fn append_text(mut buffer [max_output_bytes]u8, start int, text string) int {
	mut used := start
	for index in 0 .. text.len {
		buffer[used] = text[index]
		used++
	}
	return used
}

fn append_number(mut buffer [max_output_bytes]u8, start int, value i64) int {
	mut used := start
	mut reversed := [20]u8{}
	mut remaining := value
	mut count := 0
	for {
		unsafe { reversed[count] = u8(`0`) + u8(remaining % 10) }
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
	return used
}

@[export: 'benchmarkgame_recursive']
pub fn benchmarkgame_recursive(n i64, output &u8, output_capacity usize) i64 {
	if n < 0 || n > max_n { return -1 }
	if unsafe { output == nil } { return -2 }

	mut staged := [max_output_bytes]u8{}
	mut used := 0
	used = append_text(mut staged, used, 'Ack(3,')
	used = append_number(mut staged, used, n + 1)
	used = append_text(mut staged, used, '): ')
	used = append_number(mut staged, used, ackermann_value(3, n + 1))
	used = append_text(mut staged, used, '\nFib(')
	used = append_number(mut staged, used, 28 + n)
	used = append_text(mut staged, used, '.0): ')
	used = append_number(mut staged, used, i64(fibonacci_float(f64(28 + n))))
	used = append_text(mut staged, used, '.0\nTak(')
	used = append_number(mut staged, used, 3 * n)
	used = append_text(mut staged, used, ',')
	used = append_number(mut staged, used, 2 * n)
	used = append_text(mut staged, used, ',')
	used = append_number(mut staged, used, n)
	used = append_text(mut staged, used, '): ')
	used = append_number(mut staged, used, takeuchi_integer(3 * n, 2 * n, n))
	used = append_text(mut staged, used, '\nFib(3): ')
	used = append_number(mut staged, used, fibonacci_integer(3))
	used = append_text(mut staged, used, '\nTak(3.0,2.0,1.0): ')
	used = append_number(mut staged, used, i64(takeuchi_float(3.0, 2.0, 1.0)))
	used = append_text(mut staged, used, '.0\n')

	if output_capacity < usize(used) { return -2 }
	for index in 0 .. used { unsafe { output[index] = staged[index] } }
	return i64(used)
}
