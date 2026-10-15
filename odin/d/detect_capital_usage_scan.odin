package detect_capital_usage_scan

import "core:c"

MAX_LENGTH :: 1024
is_upper :: proc "c" (value: i64) -> bool { return value >= 65 && value <= 90 }
is_lower :: proc "c" (value: i64) -> bool { return value >= 97 && value <= 122 }

// Recheck the whole word for every uppercase byte after the first.
@(export)
detect_capital_usage_scan :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if !is_upper(input[index]) && !is_lower(input[index]) do return -1
	}
	for index := c.size_t(1); index < length; index += 1 {
		if is_upper(input[index]) {
			all_upper := true
			for check := c.size_t(0); check < length; check += 1 {
				if is_lower(input[check]) { all_upper = false; break }
			}
			if !all_upper do return 0
		}
	}
	return 1
}
