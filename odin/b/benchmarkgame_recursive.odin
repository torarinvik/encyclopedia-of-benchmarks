package benchmarkgame_recursive

import "core:c"

MAX_N :: 10
MAX_OUTPUT_BYTES :: 89

ackermann_value :: proc(x, y: i64) -> i64 {
	if x == 0 do return y + 1
	return ackermann_value(x - 1, if y == 0 { i64(1) } else { ackermann_value(x, y - 1) })
}

fibonacci_integer :: proc(n: i64) -> i64 {
	if n < 2 do return 1
	return fibonacci_integer(n - 2) + fibonacci_integer(n - 1)
}

fibonacci_float :: proc(n: f64) -> f64 {
	if n < 2.0 do return 1.0
	return fibonacci_float(n - 2.0) + fibonacci_float(n - 1.0)
}

takeuchi_integer :: proc(x, y, z: i64) -> i64 {
	if y < x {
		return takeuchi_integer(takeuchi_integer(x - 1, y, z),
			takeuchi_integer(y - 1, z, x), takeuchi_integer(z - 1, x, y))
	}
	return z
}

takeuchi_float :: proc(x, y, z: f64) -> f64 {
	if y < x {
		return takeuchi_float(takeuchi_float(x - 1.0, y, z),
			takeuchi_float(y - 1.0, z, x), takeuchi_float(z - 1.0, x, y))
	}
	return z
}

append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text {
		buffer[used^] = byte
		used^ += 1
	}
}

append_number :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: i64) {
	var reversed: [20]u8
	remaining := value
	count := 0
	for {
		reversed[count] = u8('0') + u8(remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[used^] = reversed[count]
		used^ += 1
	}
}

@(export)
benchmarkgame_recursive :: proc "c" (n: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if n < 0 || n > MAX_N do return -1
	if output == nil do return -2

	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	append_text(&staged, &used, "Ack(3,")
	append_number(&staged, &used, n + 1)
	append_text(&staged, &used, "): ")
	append_number(&staged, &used, ackermann_value(3, n + 1))
	append_text(&staged, &used, "\nFib(")
	append_number(&staged, &used, 28 + n)
	append_text(&staged, &used, ".0): ")
	append_number(&staged, &used, i64(fibonacci_float(f64(28 + n))))
	append_text(&staged, &used, ".0\nTak(")
	append_number(&staged, &used, 3 * n)
	append_text(&staged, &used, ",")
	append_number(&staged, &used, 2 * n)
	append_text(&staged, &used, ",")
	append_number(&staged, &used, n)
	append_text(&staged, &used, "): ")
	append_number(&staged, &used, takeuchi_integer(3 * n, 2 * n, n))
	append_text(&staged, &used, "\nFib(3): ")
	append_number(&staged, &used, fibonacci_integer(3))
	append_text(&staged, &used, "\nTak(3.0,2.0,1.0): ")
	append_number(&staged, &used, i64(takeuchi_float(3.0, 2.0, 1.0)))
	append_text(&staged, &used, ".0\n")

	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
