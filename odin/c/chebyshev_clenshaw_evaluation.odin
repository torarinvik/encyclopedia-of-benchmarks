// Clenshaw's backward recurrence for a Chebyshev-basis polynomial over a prime field.
package chebyshev_clenshaw_evaluation

import "core:c"

MODULUS :: i64(998244353)
MAX_DEGREE :: 16
MAX_PARSEABLE_LENGTH :: 21

reduce_field :: proc(value: i64) -> i64 {
	reduced := value % MODULUS
	if reduced < 0 do reduced += MODULUS
	return reduced
}

@(export)
chebyshev_clenshaw_evaluation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	degree_value := input[0]
	if degree_value < 0 || degree_value > MAX_DEGREE do return -1
	degree := int(degree_value)
	if int(length) != degree + 3 do return -1
	x := input[1]
	if x < 0 || x >= MODULUS do return -1
	for i := 0; i <= degree; i += 1 {
		if input[2 + i] < 0 || input[2 + i] >= MODULUS do return -1
	}

	twice_x := 2 * x % MODULUS
	next_one := i64(0)
	next_two := i64(0)
	for k := degree; k > 0; k -= 1 {
		current := reduce_field(input[2 + k] + twice_x * next_one - next_two)
		next_two = next_one
		next_one = current
	}
	return reduce_field(input[2] + x * next_one - next_two)
}
