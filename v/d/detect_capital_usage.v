module detect_capital_usage

const max_length = 1024

fn is_capital_upper(value i64) bool { return value >= 65 && value <= 90 }
fn is_capital_lower(value i64) bool { return value >= 97 && value <= 122 }

// Classify capitalization by counting uppercase letters.
@[export: 'detect_capital_usage']
pub fn detect_capital_usage(input &i64, length usize) i64 {
	if length > max_length { return -1 }
	mut uppercase_count := usize(0)
	for index in 0 .. length {
		value := unsafe { input[index] }
		if !is_capital_upper(value) && !is_capital_lower(value) { return -1 }
		if is_capital_upper(value) { uppercase_count++ }
	}
	if uppercase_count == 0 || uppercase_count == length ||
		(uppercase_count == 1 && length > 0 && unsafe { is_capital_upper(input[0]) }) { return 1 }
	return 0
}
