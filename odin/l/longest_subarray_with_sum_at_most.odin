package longest_subarray_with_sum_at_most
import "core:c"
INVALID_RESULT :: i64 = -1
MAX_DOMAIN_VALUE :: i64 = 2_147_483_647
MAX_INPUT_LENGTH :: c.size_t = 259
@(export)
longest_subarray_with_sum_at_most :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	target, raw_count := input[0], input[1]
	if target < 0 || target > MAX_DOMAIN_VALUE || raw_count < 0 || raw_count > 256 do return INVALID_RESULT
	count := int(raw_count)
	if length != c.size_t(count + 2) do return INVALID_RESULT
	for index := 0; index < count; index += 1 {
		value := input[index + 2]
		if value < 0 || value > MAX_DOMAIN_VALUE do return INVALID_RESULT
	}
	left, best_length := 0, 0
	window_sum: i64 = 0
	for right := 0; right < count; right += 1 {
		window_sum += input[right + 2]
		for window_sum > target && left <= right {
			window_sum -= input[left + 2]
			left += 1
		}
		current_length := 0
		if left <= right do current_length = right - left + 1
		if current_length > best_length do best_length = current_length
	}
	return i64(best_length)
}
