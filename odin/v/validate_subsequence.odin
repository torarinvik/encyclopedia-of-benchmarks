package validate_subsequence

import "core:c"

@(export)
validate_subsequence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 8194 do return -1
	if values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096 do return -1
	array_length := int(values[0])
	sequence_length := int(values[1])
	if length != 2 + c.size_t(array_length) + c.size_t(sequence_length) do return -1
	for i in 2..<length {
		if values[i] < -2147483648 || values[i] > 2147483647 do return -1
	}

	if array_length == 0 do return 0
	if sequence_length == 0 do return 1
	sequence_start := 2 + array_length
	array_index := 0
	sequence_index := 0
	for sequence_index < sequence_length && array_index < array_length {
		if values[sequence_start + sequence_index] == values[2 + array_index] {
			sequence_index += 1
		}
		array_index += 1
	}
	return if sequence_index == sequence_length then 1 else 0
}
