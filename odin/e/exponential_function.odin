package exponential_function

import "core:math"

@(export)
exponential_function :: proc "c" (power: f64, term_count: f64) -> f64 {
	if !(power >= -10.0 && power <= 10.0 && term_count >= 0.0 && term_count <= 32.0) do return -1.0e300
	n := int(term_count)
	if f64(n) != term_count do return -1.0e300
	if n == 0 do return 1.0

	output := 0.0
	factorial := 1.0
	for i := 0; i < n; i += 1 {
		output += math.pow(power, f64(i)) / factorial
		factorial *= f64(i + 1)
	}
	return output
}
