package shootout_heapsort

import "core:c"

MAX_LENGTH :: 8192
OUTPUT_BYTES :: 9
MODULUS :: i64(139968)
MULTIPLIER :: i64(3877)
INCREMENT :: i64(29573)

source_heapsort :: proc(n: int, values: []f64) {
	ir := n
	l := (n / 2) + 1
	for {
		var rra: f64
		if l > 1 {
			l -= 1
			rra = values[l]
		} else {
			rra = values[ir]
			values[ir] = values[1]
			ir -= 1
			if ir == 1 {
				values[1] = rra
				return
			}
		}
		i := l
		j := l * 2
		for j <= ir {
			if j < ir && values[j] < values[j + 1] { j += 1 }
			if rra < values[j] {
				values[i] = values[j]
				i = j
				j += i
			} else {
				j = ir + 1
			}
		}
		values[i] = rra
	}
}

write_fixed_six :: proc(value: f64, output: [^]u8) {
	millionths := u32(value * 1_000_000.0 + 0.5)
	whole := millionths / 1_000_000
	fraction := millionths % 1_000_000
	output[0] = u8(48 + whole)
	output[1] = u8(46)
	divisor := u32(100_000)
	for index := 2; index < 8; index += 1 {
		output[index] = u8('0' + (fraction / divisor) % 10)
		divisor /= 10
	}
	output[8] = u8(10)
}

@(export)
shootout_heapsort :: proc "c" (length: i64, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if length < 2 || length > MAX_LENGTH do return -1
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2

	values: [MAX_LENGTH + 1]f64
	state := i64(42)
	for index := 1; index <= int(length); index += 1 {
		state = (state * MULTIPLIER + INCREMENT) % MODULUS
		values[index] = 1.0 * f64(state) / f64(MODULUS)
	}
	source_heapsort(int(length), values[:])
	write_fixed_six(values[int(length)], output)
	return OUTPUT_BYTES
}
