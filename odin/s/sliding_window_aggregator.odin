package sliding_window_aggregator

import "core:c"

MAX_CAPACITY :: 64
MAX_COUNT :: 256
MAX_VALID_INPUT_LENGTH :: c.size_t(258)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(259)
INVALID_RESULT :: i64(-9223372036854775807 - 1)

sliding_window_aggregator :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return INVALID_RESULT
	capacity_value, count_value := input[0], input[1]
	if capacity_value < 1 || capacity_value > MAX_CAPACITY || count_value < 1 || count_value > MAX_COUNT do return INVALID_RESULT
	capacity, count := int(capacity_value), int(count_value)
	if length != c.size_t(count + 2) || length > MAX_VALID_INPUT_LENGTH do return INVALID_RESULT
	var window: [MAX_CAPACITY]i64
	head, size := 0, 0
	sum := i64(0)
	for index in 0 ..< count {
		value := input[index+2]
		if value < -1_000_000 || value > 1_000_000 do return INVALID_RESULT
		if size < capacity {
			position := (head + size) % capacity
			window[position] = value
			size += 1
			sum += value
		} else {
			sum -= window[head]
			window[head] = value
			sum += value
			head = (head + 1) % capacity
		}
	}
	return sum
}
