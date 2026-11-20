package elias_fano_monotone_sequence

import "core:c"

MAX_VALUES :: 32
MAX_HIGH_BITS :: 96
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(35)

@(export)
elias_fano_monotone_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	count_value := input[0]
	upper_bound := input[1]
	if count_value < 1 || count_value > MAX_VALUES || upper_bound < 0 || upper_bound > 1_000_000 ||
		count_value > upper_bound+1 do return -1
	count := int(count_value)
	if length != c.size_t(count+2) do return -1

	values: [MAX_VALUES]i64
	previous: i64 = -1
	for i := 0; i < count; i += 1 {
		value := input[i+2]
		if value < 0 || value > upper_bound || value < previous do return -1
		values[i] = value
		previous = value
	}

	low_width := 0
	for i64(count)*(i64(1) << (low_width+1)) <= upper_bound+1 { low_width += 1 }
	width := i64(1) << low_width
	low_mask := width-1
	high_length := int(upper_bound/width)+count
	if high_length < count || high_length > MAX_HIGH_BITS do return -1

	low_parts: [MAX_VALUES]i64
	high_bits: [MAX_HIGH_BITS]bool
	for i := 0; i < count; i += 1 {
		low_parts[i] = values[i] & low_mask
		position := int(values[i]/width)+i
		if position < 0 || position >= high_length do return -1
		high_bits[position] = true
	}

	checksum: i64 = 0
	item_index := 0
	for position := 0; position < high_length; position += 1 {
		if high_bits[position] {
			if item_index >= count || position < item_index do return -1
			high_part := i64(position-item_index)
			decoded := high_part*width+low_parts[item_index]
			checksum += i64(item_index+1)*decoded
			item_index += 1
		}
	}
	if item_index != count do return -1
	return checksum
}
