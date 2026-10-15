package abbreviation

import "core:c"

// Check whether lowercase source letters can be capitalized or deleted.
@(export)
abbreviation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 258 do return -1
	source_length := values[0]
	target_length := values[1]
	if source_length < 0 || source_length > 128 || target_length < 0 || target_length > 128 do return -1
	if length != 2 + c.size_t(source_length) + c.size_t(target_length) do return -1
	for index: c.size_t = 0; index < c.size_t(source_length); index += 1 {
		value := values[2 + index]
		if !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) do return -1
	}
	for index: c.size_t = 0; index < c.size_t(target_length); index += 1 {
		value := values[2 + c.size_t(source_length) + index]
		if value < 'A' || value > 'Z' do return -1
	}

	current: [129]bool
	next: [129]bool
	current[0] = true
	for source_index: c.size_t = 0; source_index < c.size_t(source_length); source_index += 1 {
		for target_index: c.size_t = 0; target_index <= c.size_t(target_length); target_index += 1 {
			next[target_index] = false
		}
		source := values[2 + source_index]
		uppercase := source
		if source >= 'a' && source <= 'z' do uppercase -= 'a' - 'A'
		for target_index: c.size_t = 0; target_index <= c.size_t(target_length); target_index += 1 {
			if !current[target_index] do continue
			if source >= 'a' && source <= 'z' do next[target_index] = true
			if target_index < c.size_t(target_length) &&
				uppercase == values[2 + c.size_t(source_length) + target_index] {
				next[target_index + 1] = true
			}
		}
		for target_index: c.size_t = 0; target_index <= c.size_t(target_length); target_index += 1 {
			current[target_index] = next[target_index]
		}
	}
	if current[c.size_t(target_length)] do return 1
	return 0
}
