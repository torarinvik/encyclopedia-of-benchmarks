module burnside_bracelets

const max_n = 10
const max_input_values = 3
const output_bytes = 8

fn burnside_cycle_count(n int, shift int, reflection bool) int {
	mut seen := [10]bool{}
	mut cycles := 0
	for start in 0 .. n {
		if seen[start] { continue }
		cycles++
		mut position := start
		for !seen[position] {
			seen[position] = true
			if reflection { position = (shift + n - position) % n }
			else { position = (position + shift) % n }
		}
	}
	return cycles
}

fn burnside_fixed_colorings(n int, shift int, reflection bool, colors i64) i64 {
	cycles := burnside_cycle_count(n, shift, reflection)
	mut result := i64(1)
	for _ in 0 .. cycles { result *= colors }
	return result
}

fn burnside_store_i64_le(output &u8, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. output_bytes { output[byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'burnside_bracelets']
pub fn burnside_bracelets(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_values { return -1 }
		if length != 2 { return -1 }
		n_value := input[0]
		colors := input[1]
		if n_value < 1 || n_value > max_n || colors < 0 || colors > 3 { return -1 }
		n := int(n_value)

		mut fixed_sum := i64(0)
		for shift in 0 .. n {
			fixed_sum += burnside_fixed_colorings(n, shift, false, colors)
			fixed_sum += burnside_fixed_colorings(n, shift, true, colors)
		}
		answer := fixed_sum / i64(2 * n)
		if output == nil || capacity < output_bytes { return -2 }
		burnside_store_i64_le(output, answer)
		return output_bytes
	}
}
