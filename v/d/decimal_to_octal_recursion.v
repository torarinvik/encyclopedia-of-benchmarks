module decimal_to_octal_recursion

fn encode_octal_digits(value i64) i64 {
	if value == 0 { return 0 }
	return encode_octal_digits(value / 8) * 10 + value % 8
}

// Recursively encode octal digits as a decimal integer.
@[export: 'decimal_to_octal_recursion']
pub fn decimal_to_octal_recursion(value i64) i64 {
	if value < 0 || value > 295600127 { return -1 }
	return encode_octal_digits(value)
}
