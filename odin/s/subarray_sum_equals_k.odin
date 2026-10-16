package subarray_sum_equals_k

import "core:c"

Invalid_Result :: i64(-9223372036854775807 - 1)
Max_Items :: 512
Table_Size :: 2048

slot_for :: proc(value: i64) -> int {
	magnitude := value
	if magnitude < 0 do magnitude = -magnitude
	return int(magnitude % i64(Table_Size))
}

@(export)
subarray_sum_equals_k :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > Max_Items + 2 do return Invalid_Result
	count_value := input[0]
	target := input[1]
	if count_value < 0 || count_value > i64(Max_Items) || target < -2147483648 || target > 2147483647 do return Invalid_Result
	count := int(count_value)
	if int(length) != count + 2 do return Invalid_Result
	for index := 0; index < count; index += 1 {
		if input[index + 2] < -2147483648 || input[index + 2] > 2147483647 do return Invalid_Result
	}

	keys: [Table_Size]i64
	frequencies: [Table_Size]i64
	frequencies[0] = 1
	prefix_sum: i64 = 0
	result: i64 = 0
	for index := 0; index < count; index += 1 {
		prefix_sum += input[index + 2]
		required := prefix_sum - target
		slot := slot_for(required)
		for frequencies[slot] != 0 && keys[slot] != required { slot = (slot + 1) % Table_Size }
		result += frequencies[slot]

		slot = slot_for(prefix_sum)
		for frequencies[slot] != 0 && keys[slot] != prefix_sum { slot = (slot + 1) % Table_Size }
		if frequencies[slot] == 0 do keys[slot] = prefix_sum
		frequencies[slot] += 1
	}
	return result
}
