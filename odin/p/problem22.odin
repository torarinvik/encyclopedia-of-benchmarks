package problem22

import "core:c"

const MAX_NAMES :: 6000
const MAX_NAME_LENGTH :: 19
const MAX_INPUT_LENGTH :: 100001

compare_names :: proc "contextless" (input: [^]i64, offsets: [^]int, name_lengths: [^]int, first, second: int) -> int {
	first_length := name_lengths[first]
	second_length := name_lengths[second]
	shared_length := min(first_length, second_length)
	for index := 0; index < shared_length; index += 1 {
		first_letter := input[offsets[first] + index]
		second_letter := input[offsets[second] + index]
		if first_letter < second_letter do return -1
		if first_letter > second_letter do return 1
	}
	if first_length < second_length do return -1
	if first_length > second_length do return 1
	return 0
}

@(export)
problem22 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_NAMES do return -1
	count := int(raw_count)
	offsets: [MAX_NAMES]int = {}
	name_lengths: [MAX_NAMES]int = {}
	order: [MAX_NAMES]int = {}
	cursor := 1
	for name := 0; name < count; name += 1 {
		if cursor >= int(length) do return -1
		raw_name_length := input[cursor]
		cursor += 1
		if raw_name_length < 1 || raw_name_length > MAX_NAME_LENGTH do return -1
		name_length := int(raw_name_length)
		if name_length > int(length) - cursor do return -1
		offsets[name] = cursor
		name_lengths[name] = name_length
		for letter := 0; letter < name_length; letter += 1 {
			value := input[cursor + letter]
			if value < 1 || value > 26 do return -1
		}
		cursor += name_length
		order[name] = name
	}
	if cursor != int(length) do return -1

	gaps: [8]int = {701, 301, 132, 57, 23, 10, 4, 1}
	for gap_index := 0; gap_index < 8; gap_index += 1 {
		gap := gaps[gap_index]
		if gap >= count do continue
		for index := gap; index < count; index += 1 {
			key := order[index]
			position := index
			for position >= gap && compare_names(input, &offsets[0], &name_lengths[0], order[position-gap], key) > 0 {
				order[position] = order[position-gap]
				position -= gap
			}
			order[position] = key
		}
	}

	total := i64(0)
	for position := 0; position < count; position += 1 {
		name := order[position]
		score := i64(0)
		for letter := 0; letter < name_lengths[name]; letter += 1 {
			score += input[offsets[name] + letter]
		}
		total += i64(position + 1) * score
	}
	return total
}
