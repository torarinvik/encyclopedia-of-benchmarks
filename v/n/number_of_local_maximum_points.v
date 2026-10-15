module number_of_local_maximum_points

const max_length = 4096
const int32_min_value = i64(-2_147_483_648)
const int32_max_value = i64(2_147_483_647)

fn is_local_maximum(values []i64, index int) bool {
	if index == 0 { return values[0] > values[1] }
	if index == values.len - 1 { return values[index] > values[index - 1] }
	return values[index] > values[index - 1] && values[index] > values[index + 1]
}

fn count_range(values []i64, start int, ending int) i64 {
	if start == ending { return if is_local_maximum(values, start) { i64(1) } else { i64(0) } }
	middle := (start + ending) / 2
	return count_range(values, start, middle) + count_range(values, middle + 1, ending)
}

// Count strict local maxima using the pinned recursive partition.
@[export: 'number_of_local_maximum_points']
pub fn number_of_local_maximum_points(values &i64, length usize) i64 {
	if length == 0 || length > max_length { return -1 }
	unsafe {
		data := values[..length]
		for value in data {
			if value < int32_min_value || value > int32_max_value { return -1 }
		}
		if length == 1 { return 0 }
		return count_range(data, 0, int(length) - 1)
	}
}
