package circular_convolution

import "core:c"

@(export)
circular_convolution :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 do return -1
	raw_a_length := values[0]
	raw_b_length := values[1]
	if raw_a_length < 1 || raw_a_length > 8 || raw_b_length < 1 || raw_b_length > 8 do return -1
	a_length := int(raw_a_length)
	b_length := int(raw_b_length)
	if length != c.size_t(2 + a_length + b_length) do return -1
	for index := 0; index < a_length + b_length; index += 1 {
		if values[2 + index] < -2 || values[2 + index] > 2 do return -1
	}
	n := max(a_length, b_length)
	if output == nil || output_capacity < c.size_t(n) do return -2

	for k := 0; k < n; k += 1 {
		sum := i64(0)
		for i := 0; i < n; i += 1 {
			b_index := (k + n - i) % n
		a_value := i64(0)
			if i < a_length do a_value = values[2 + i]
			b_value := i64(0)
			if b_index < b_length do b_value = values[2 + a_length + b_index]
			sum += a_value * b_value
		}
		encoded := sum
		if encoded < 0 do encoded += 256
		output[k] = u8(encoded)
	}
	return i64(n)
}
