package median_search

import "core:c"

MAX_VALUES :: 25
MAX_INPUT_LENGTH :: c.size_t(28)

insertion_sort :: proc(values: []i64) {
	for index := 1; index < len(values); index += 1 {
		value := values[index]
		position := index
		for position > 0 && values[position-1] > value {
			values[position] = values[position-1]
			position -= 1
		}
		values[position] = value
	}
}

select_kth :: proc(values: []i64, rank: int) -> i64 {
	var medians: [5]i64
	median_count := 0
	for start := 0; start < len(values); start += 5 {
		end := start + 5
		if end > len(values) {
			end = len(values)
		}
		insertion_sort(values[start:end])
		medians[median_count] = values[(start+end)/2]
		median_count += 1
	}
	insertion_sort(medians[:median_count])
	pivot := medians[(median_count-1)/2]

	var lower, higher: [MAX_VALUES]i64
	lower_count, higher_count := 0, 0
	for value in values {
		if value < pivot {
			lower[lower_count] = value
			lower_count += 1
		} else if value > pivot {
			higher[higher_count] = value
			higher_count += 1
		}
	}
	if rank < lower_count {
		return select_kth(lower[:lower_count], rank)
	}
	if rank > lower_count {
		return select_kth(higher[:higher_count], rank-lower_count-1)
	}
	return pivot
}

@(export)
median_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	count_value, rank_value := input[0], input[1]
	if count_value < 1 || count_value > MAX_VALUES || rank_value < 0 || rank_value >= count_value do return -1
	count := int(count_value)
	if length != c.size_t(count + 2) do return -1

	var values: [MAX_VALUES]i64
	for index := 0; index < count; index += 1 {
		value := input[index+2]
		if value < 0 || value > 2_147_483_647 do return -1
		for previous := 0; previous < index; previous += 1 {
			if values[previous] == value do return -1
		}
		values[index] = value
	}
	return select_kth(values[:count], int(rank_value))
}
