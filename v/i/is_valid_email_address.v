fn ascii_letter(value i64) bool { return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) }
fn ascii_digit(value i64) bool { return value >= 48 && value <= 57 }
fn local_special(value i64) bool {
	return value == 33 || value == 35 || value == 36 || value == 37 || value == 38 || value == 39 ||
		value == 40 || value == 41 || value == 42 || value == 43 || value == 45 || value == 46 ||
		value == 47 || value == 61 || value == 63 || value == 94 || value == 95 || value == 96 ||
		value == 123 || value == 124 || value == 125 || value == 126
}
fn local_allowed(value i64) bool { return ascii_letter(value) || ascii_digit(value) || local_special(value) }
fn domain_allowed(value i64) bool { return ascii_letter(value) || ascii_digit(value) || value == 46 || value == 45 }

@[export: 'is_valid_email_address']
pub fn is_valid_email_address(values &i64, length usize) i64 {
	if length > 320 { return 0 }
	if unsafe { values == nil } && length > 0 { return -1 }
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < 0 || value > 0x10ffff { return -1 }
	}
	mut at := length
	for i in 0 .. length {
		if unsafe { values[i] == 64 } {
			if at != length { return 0 }
			at = i
		}
	}
	if at == length { return 0 }
	domain_start := at + 1
	if at > 64 || length - domain_start > 255 { return 0 }
	for i in 0 .. at {
		value := unsafe { values[i] }
		if !local_allowed(value) { return 0 }
		if value == 46 && (i == 0 || i + 1 == at || unsafe { values[i - 1] == 46 }) { return 0 }
	}
	for i in domain_start .. length {
		value := unsafe { values[i] }
		if !domain_allowed(value) { return 0 }
		if value == 45 && i == domain_start { return 0 }
		if value == 46 && (i == domain_start || i + 1 == length || unsafe { values[i - 1] == 46 }) { return 0 }
	}
	return 1
}
