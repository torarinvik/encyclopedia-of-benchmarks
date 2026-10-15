module maximum_twin_sum_of_linked_list

const max_length = 1024

// Copy positive list values, then scan each mirrored twin pair.
@[export: 'maximum_twin_sum_of_linked_list']
pub fn maximum_twin_sum_of_linked_list(values &i64, length usize) i64 {
	if length < 2 || length > max_length || length % 2 != 0 { return -1 }
	mut copied := [max_length]i32{}
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 1 || value > 100000 { return -1 }
		copied[index] = i32(value)
	}
	mut maximum := i64(0)
	for index in 0 .. length / 2 {
		twin_sum := i64(copied[index]) + i64(copied[length - index - 1])
		if twin_sum > maximum { maximum = twin_sum }
	}
	return maximum
}
