package is_subsequence

MAX_SEQUENCE_LENGTH :: 4096
MAX_PACKED_LENGTH :: 8194

is_unicode_scalar :: proc "contextless" (value: i64) -> bool {
	return value >= 0 && value <= 1_114_111 && !(value >= 55_296 && value <= 57_343)
}

@(export)
is_subsequence :: proc "c" (input: [^]i64, length: int) -> i64 {
	if input == nil || length < 2 || length > MAX_PACKED_LENGTH do return -1
	if input[0] < 0 || input[0] > i64(MAX_SEQUENCE_LENGTH) ||
		input[1] < 0 || input[1] > i64(MAX_SEQUENCE_LENGTH) do return -1
	main_length := int(input[0])
	subsequence_length := int(input[1])
	if length != 2 + main_length + subsequence_length do return -1
	for index := 2; index < length; index += 1 {
		if !is_unicode_scalar(input[index]) do return -1
	}

	subsequence_start := 2 + main_length
	main_index := 0
	subsequence_index := 0
	for subsequence_index < subsequence_length && main_index < main_length {
		if input[subsequence_start + subsequence_index] == input[2 + main_index] do subsequence_index += 1
		main_index += 1
	}
	return if subsequence_index == subsequence_length then i64(1) else i64(0)
}
