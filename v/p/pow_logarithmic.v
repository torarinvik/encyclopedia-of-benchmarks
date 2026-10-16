module pow_logarithmic
const invalid_result = i64(-9223372036854775807 - 1)
const max_parseable_input_length = 3
fn pow_logarithmic_value(base i64, exponent int) i64 {
	if exponent == 0 { return 1 }
	half := pow_logarithmic_value(base, exponent / 2)
	square := half * half
	if exponent % 2 == 0 { return square }
	return square * base
}
@[export: 'pow_logarithmic']
pub fn pow_logarithmic(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input_length { return invalid_result }
	unsafe {
		if length != 2 { return invalid_result }
		base, exponent := input[0], input[1]
		if base < -10 || base > 10 || exponent < 0 || exponent > 15 { return invalid_result }
		return pow_logarithmic_value(base, int(exponent))
	}
}
