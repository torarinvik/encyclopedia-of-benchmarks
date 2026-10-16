package is_valid_email_address

import "core:c"

ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}
ascii_digit :: proc "contextless" (value: i64) -> bool { return value >= 48 && value <= 57 }
local_special :: proc "contextless" (value: i64) -> bool {
	return value == 33 || value == 35 || value == 36 || value == 37 || value == 38 || value == 39 ||
		value == 40 || value == 41 || value == 42 || value == 43 || value == 45 || value == 46 ||
		value == 47 || value == 61 || value == 63 || value == 94 || value == 95 || value == 96 ||
		value == 123 || value == 124 || value == 125 || value == 126
}
local_allowed :: proc "contextless" (value: i64) -> bool { return ascii_letter(value) || ascii_digit(value) || local_special(value) }
domain_allowed :: proc "contextless" (value: i64) -> bool { return ascii_letter(value) || ascii_digit(value) || value == 46 || value == 45 }

@(export)
is_valid_email_address :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 320 do return 0
	if values == nil && length > 0 do return -1
	n := int(length)
	for i in 0..<n { if values[i] < 0 || values[i] > 0x10ffff do return -1 }
	at := n
	for i in 0..<n {
		if values[i] == 64 { if at != n do return 0; at = i }
	}
	if at == n do return 0
	domain_start := at + 1
	if at > 64 || n - domain_start > 255 do return 0
	for i in 0..<at {
		value := values[i]
		if !local_allowed(value) do return 0
		if value == 46 && (i == 0 || i + 1 == at || values[i-1] == 46) do return 0
	}
	for i in domain_start..<n {
		value := values[i]
		if !domain_allowed(value) do return 0
		if value == 45 && i == domain_start do return 0
		if value == 46 && (i == domain_start || i + 1 == n || values[i-1] == 46) do return 0
	}
	return 1
}
