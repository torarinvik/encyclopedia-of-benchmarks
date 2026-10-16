module minimum_waiting_time

@[export: 'minimum_waiting_time']
pub fn minimum_waiting_time(values &i64, length usize) i64 {
	if length > 64 { return i64(-9223372036854775807) - 1 }
	if length == 0 { return 0 }
	if unsafe { values == nil } { return i64(-9223372036854775807) - 1 }
	unsafe {
		mut durations := [64]i64{}
		for index in 0 .. length {
			value := values[index]
			if value < 0 || value > 1000 { return i64(-9223372036854775807) - 1 }
			durations[index] = value
		}
		for index in 1 .. length {
			key := durations[index]
			mut cursor := index
			for cursor > 0 && durations[cursor - 1] > key {
				durations[cursor] = durations[cursor - 1]
				cursor--
			}
			durations[cursor] = key
		}
		mut total := i64(0)
		for index in 0 .. length {
			total += durations[index] * i64(length - index - 1)
		}
		return total
	}
}
