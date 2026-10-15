module average_mode

@[export: 'average_mode']
pub fn average_mode(values &i64, length usize) i64 {
	if length == 0 || length > 64 { return -1 }
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < 0 || value > 1000 { return -1 }
	}

	mut mode := i64(-1)
	mut maximum_count := usize(0)
	mut tied := false
	for i in 0 .. length {
		value := unsafe { values[i] }
		mut seen := false
		for before in 0 .. i {
			if unsafe { values[before] == value } { seen = true; break }
		}
		if seen { continue }

		mut count := usize(0)
		for j in 0 .. length {
			if unsafe { values[j] == value } { count++ }
		}
		if count > maximum_count {
			maximum_count = count
			mode = value
			tied = false
		} else if count == maximum_count {
			tied = true
		}
	}
	if tied { return -1 }
	return mode
}
