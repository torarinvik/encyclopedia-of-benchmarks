package kth_smallest

import "core:c"

MAX_LENGTH :: 256
INVALID_RESULT :: i64(-9223372036854775807 - 1)

partition_values :: proc "contextless" (values: [^]i32, low_value, high_value: int) -> int {
	pivot := high_value
	i := low_value
	j := high_value - 1
	for {
		for values[i] < values[pivot] do i += 1
		for j > 0 && values[j] > values[pivot] do j -= 1
		if j == 0 || i >= j do break
		if values[i] == values[j] {
			i += 1
			j -= 1
		} else {
			temporary := values[i]
			values[i] = values[j]
			values[j] = temporary
		}
	}
	temporary := values[i]
	values[i] = values[pivot]
	values[pivot] = temporary
	return i
}

@(export)
kth_smallest :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_LENGTH + 2 do return INVALID_RESULT
	n_value := input[0]
	k_value := input[1]
	if n_value < 1 || n_value > MAX_LENGTH || k_value < 1 || k_value > n_value || length != c.size_t(n_value + 2) do return INVALID_RESULT
	n := int(n_value)
	values: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 2]
		if value < -2147483648 || value > 2147483647 do return INVALID_RESULT
		values[index] = i32(value)
	}
	low := 0
	high := n - 1
	k := int(k_value)
	for low < high {
		pivot := partition_values(&values[0], low, high)
		pivot_rank := pivot - low + 1
		if k == pivot_rank do return i64(values[pivot])
		if k < pivot_rank {
			high = pivot - 1
		} else {
			low = pivot + 1
			k -= pivot_rank
		}
	}
	return i64(values[low])
}
