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

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() {
		buffer[used] = byte
		used++
	}
}

fn append_number(mut buffer []u8, mut used int, value i64) {
	mut reversed := []u8{len: 20}
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
}

@[export: 'benchmarkgame_recursive']
pub fn benchmarkgame_recursive(n i64, mut output &u8, output_capacity usize) i64 {
	if n < 0 || n > max_n { return -1 }
	if unsafe { output == nil } { return -2 }

	mut staged := []u8{len: max_output_bytes}
	mut used := 0
	append_text(mut staged, mut used, 'Ack(3,')
	append_number(mut staged, mut used, n + 1)
	append_text(mut staged, mut used, '): ')
	append_number(mut staged, mut used, ackermann_value(3, n + 1))
	append_text(mut staged, mut used, '\nFib(')
	append_number(mut staged, mut used, 28 + n)
	append_text(mut staged, mut used, '.0): ')
	append_number(mut staged, mut used, i64(fibonacci_float(f64(28 + n))))
	append_text(mut staged, mut used, '.0\nTak(')
	append_number(mut staged, mut used, 3 * n)
	append_text(mut staged, mut used, ',')
	append_number(mut staged, mut used, 2 * n)
	append_text(mut staged, mut used, ',')
	append_number(mut staged, mut used, n)
	append_text(mut staged, mut used, '): ')
	append_number(mut staged, mut used, takeuchi_integer(3 * n, 2 * n, n))
	append_text(mut staged, mut used, '\nFib(3): ')
	append_number(mut staged, mut used, fibonacci_integer(3))
	append_text(mut staged, mut used, '\nTak(3.0,2.0,1.0): ')
	append_number(mut staged, mut used, i64(takeuchi_float(3.0, 2.0, 1.0)))
	append_text(mut staged, mut used, '.0\n')

	if output_capacity < usize(used) { return -2 }
	for index in 0 .. used { unsafe { output[index] = staged[index] } }
	return i64(used)
}
