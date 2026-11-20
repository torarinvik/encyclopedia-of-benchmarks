package weniger_pochhammer_partial_sum_transform

import "core:c"

MIN_WORDS :: 7
MAX_WORDS :: 17
OUTPUT_BYTES :: 16

weniger_gcd :: proc(a_input, b_input: i64) -> i64 {
	a, b := a_input, b_input
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

weniger_store_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 { output[offset+byte] = u8(bits >> (8*byte)) }
}

@(export)
weniger_pochhammer_partial_sum_transform :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < MIN_WORDS || input_length > MAX_WORDS do return -1
	n0, k0 := input[0], input[1]
	if n0 < 0 || n0 > 8 || k0 < 3 || k0 > 4 do return -1
	n, k := int(n0), int(k0)
	if input_length != c.size_t(n+k+4) do return -1
	term_count := n+k+2
	for i in 0..<term_count { value := input[i+2]; if value == 0 || value < -3 || value > 3 do return -1 }

	product := i64(1)
	for r in 0..<k+1 { product *= input[n+r+3] }
	numerator, denominator := i64(0), i64(0)
	for j in 0..<k+1 {
		choose := i64(1)
		for r in 1..<j+1 { choose = choose*i64(k-r+1)/i64(r) }
		rising := i64(1)
		for offset in 0..<k-1 { rising *= i64(n+j+1+offset) }
		term := input[n+j+3]
		weight := choose*rising*(product/term)
		if j%2 != 0 { weight = -weight }
		partial := i64(0)
		for index in 0..<n+j+1 { partial += input[index+2] }
		numerator += weight*partial
		denominator += weight
	}
	if denominator == 0 do return -1
	if denominator < 0 { numerator = -numerator; denominator = -denominator }
	magnitude := numerator
	if magnitude < 0 { magnitude = -magnitude }
	divisor := weniger_gcd(magnitude, denominator)
	numerator /= divisor
	denominator /= divisor
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
	weniger_store_i64(output, 0, numerator)
	weniger_store_i64(output, 8, denominator)
	return i64(OUTPUT_BYTES)
}
