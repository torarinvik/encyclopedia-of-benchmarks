module number_of_ways_to_select_buildings

const max_length = 4096

fn count_for_target(values &i64, length usize, target i64) i64 {
	mut first_count := i64(0)
	mut middle_count := i64(0)
	mut ways := i64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value == target {
			ways += middle_count
			first_count++
		} else {
			middle_count += first_count
		}
	}
	return ways
}

// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
@[export: 'number_of_ways_to_select_buildings']
pub fn number_of_ways_to_select_buildings(values &i64, length usize) i64 {
	if length == 0 { return 0 }
	if length > max_length { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value != 48 && value != 49 { return -1 }
	}
	return count_for_target(values, length, 48) + count_for_target(values, length, 49)
}
