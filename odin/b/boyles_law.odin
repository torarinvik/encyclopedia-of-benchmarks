package boyles_law

import "core:c"

rounded_milli :: proc(numerator, denominator: i64) -> i64 {
	scaled := numerator * 1000
	quotient := scaled / denominator
	remainder := scaled % denominator
	if 2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0) do quotient += 1
	return quotient
}

@(export)
boyles_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	target, a, b, c_value := values[0], values[1], values[2], values[3]
	if target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c_value < 1 || c_value > 1000 do return -1.0e300
	 numerator, denominator: i64
	switch target {
	case 0: numerator = c_value * a; denominator = b
	case 1: numerator = b * a; denominator = c_value
	case 2: numerator = c_value * b; denominator = a
	case: numerator = c_value * a; denominator = b
	}
	return f64(rounded_milli(numerator, denominator)) / 1000.0
}
