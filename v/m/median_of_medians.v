module median_of_medians

const max_values = 25
const max_input_length = usize(28)

fn insertion_sort(mut values []i64) {
	for index in 1 .. values.len {
		value := values[index]
	mut position := index
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}
}

fn select_kth(mut values []i64, rank int) i64 {
	mut medians := [5]i64{}
	mut median_count := 0
	mut start := 0
	for start < values.len {
		mut end := start + 5
		if end > values.len {
			end = values.len
		}
		insertion_sort(mut values[start..end])
		medians[median_count] = values[(start + end) / 2]
		median_count++
		start += 5
	}
	insertion_sort(mut medians[..median_count])
	pivot := medians[(median_count - 1) / 2]

	mut lower := [max_values]i64{}
	mut higher := [max_values]i64{}
	mut lower_count := 0
	mut higher_count := 0
	for value in values {
		if value < pivot {
			lower[lower_count] = value
			lower_count++
		} else if value > pivot {
			higher[higher_count] = value
			higher_count++
		}
	}
	if rank < lower_count {
		return select_kth(mut lower[..lower_count], rank)
	}
	if rank > lower_count {
		return select_kth(mut higher[..higher_count], rank - lower_count - 1)
	}
	return pivot
}

@[export: 'median_of_medians']
pub fn median_of_medians(input &i64, length usize) i64 {
	if isnil(input) || length < 3 || length > max_input_length {
		return -1
	}
	count_value := unsafe { input[0] }
	rank_value := unsafe { input[1] }
	if count_value < 1 || count_value > max_values || rank_value < 0 || rank_value >= count_value {
		return -1
	}
	count := int(count_value)
	if length != usize(count + 2) {
		return -1
	}

	mut values := [max_values]i64{}
	for index in 0 .. count {
		value := unsafe { input[index + 2] }
		if value < 0 || value > 2_147_483_647 {
			return -1
		}
		for previous in 0 .. index {
			if values[previous] == value {
				return -1
			}
		}
		values[index] = value
	}
	return select_kth(mut values[..count], int(rank_value))
}
