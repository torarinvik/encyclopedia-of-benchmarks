module detect_capital_usage_scan

const max_length = 1024

fn is_scan_upper(value i64) bool { return value >= 65 && value <= 90 }
fn is_scan_lower(value i64) bool { return value >= 97 && value <= 122 }

// Recheck the whole word for every uppercase byte after the first.
@[export: 'detect_capital_usage_scan']
pub fn detect_capital_usage_scan(input &i64, length usize) i64 {
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if !is_scan_upper(value) && !is_scan_lower(value) { return -1 }
	}
	mut index := usize(1)
	for index < length {
		if unsafe { is_scan_upper(input[index]) } {
			mut all_upper := true
			for check in 0 .. length {
				if unsafe { is_scan_lower(input[check]) } { all_upper = false; break }
			}
			if !all_upper { return 0 }
		}
		index++
	}
	return 1
}
