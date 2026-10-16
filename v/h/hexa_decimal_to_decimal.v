module hexa_decimal_to_decimal

const max_input_length = 64
const max_parseable_input_length = 65
const invalid_result = i64(-2_147_483_649)
const uint32_modulus = u64(4_294_967_296)

@[export: 'hexa_decimal_to_decimal']
pub fn hexa_decimal_to_decimal(input &i64, length usize) i64 {
	if length > max_parseable_input_length { return invalid_result }
	if length == 0 { return 0 }
	if length > max_input_length || unsafe { input == nil } { return invalid_result }

	mut accumulator := u64(0)
	for index in 0 .. length {
		code := unsafe { input[index] }
		mut digit := i64(-1)
		if code >= 48 && code <= 57 { digit = code - 48 }
		else if code >= 65 && code <= 70 { digit = code - 55 }
		else if code >= 97 && code <= 102 { digit = code - 87 }
		if digit < 0 { return invalid_result }
		accumulator = (accumulator * 16 + u64(digit)) % uint32_modulus
	}
	if accumulator <= u64(2_147_483_647) { return i64(accumulator) }
	return i64(accumulator) - 4_294_967_296
}
