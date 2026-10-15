module abbreviation

// Check whether lowercase source letters can be capitalized or deleted.
@[export: 'abbreviation']
pub fn abbreviation(values &i64, length usize) i64 {
	if length < 2 || length > 258 { return -1 }
	source_length_value := unsafe { values[0] }
	target_length_value := unsafe { values[1] }
	if source_length_value < 0 || source_length_value > 128 || target_length_value < 0 || target_length_value > 128 {
		return -1
	}
	source_length := usize(source_length_value)
	target_length := usize(target_length_value)
	if length != 2 + source_length + target_length { return -1 }
	for index in 0 .. source_length {
		value := unsafe { values[2 + index] }
		if !((value >= `A` && value <= `Z`) || (value >= `a` && value <= `z`)) { return -1 }
	}
	for index in 0 .. target_length {
		value := unsafe { values[2 + source_length + index] }
		if value < `A` || value > `Z` { return -1 }
	}

	mut current := [129]bool{}
	mut next := [129]bool{}
	current[0] = true
	for source_index in 0 .. source_length {
		for target_index in 0 .. target_length + 1 { next[target_index] = false }
		source := unsafe { values[2 + source_index] }
		uppercase := if source >= `a` && source <= `z` { source - (`a` - `A`) } else { source }
		for target_index in 0 .. target_length + 1 {
			if !current[target_index] { continue }
			if source >= `a` && source <= `z` { next[target_index] = true }
			if target_index < target_length && uppercase == unsafe { values[2 + source_length + target_index] } {
				next[target_index + 1] = true
			}
		}
		for target_index in 0 .. target_length + 1 { current[target_index] = next[target_index] }
	}
	return if current[target_length] { 1 } else { 0 }
}
