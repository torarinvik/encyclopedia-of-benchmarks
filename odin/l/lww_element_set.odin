package lww_element_set

import "core:c"

MAX_OPERATIONS :: 24
MAX_KEYS :: 24
MAP_COUNT :: 4
MAX_PARSEABLE_INPUT_LENGTH :: 98
I32_MIN :: i64(-2_147_483_648)
I32_MAX :: i64(2_147_483_647)

@(export)
lww_element_set :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	operation_count_value := input[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	if int(input_length) != 1 + 4*operation_count do return -1

	keys: [MAP_COUNT * MAX_KEYS]i64
	timestamps: [MAP_COUNT * MAX_KEYS]i64
	map_counts: [MAP_COUNT]int
	lookup_mask := i64(0)
	lookup_index := 0

	for operation in 0..<operation_count {
		offset := 1 + 4*operation
		opcode := input[offset]
		first := input[offset + 1]
		second := input[offset + 2]
		third := input[offset + 3]
		if opcode == 0 || opcode == 1 {
			if first < 0 || first > 1 || second < I32_MIN || second > I32_MAX || third < I32_MIN || third > I32_MAX do return -1
			map_index := int(first)*2
			if opcode == 1 { map_index += 1 }
			base := map_index * MAX_KEYS
			position := 0
			for position < map_counts[map_index] && keys[base + position] != second { position += 1 }
			if position == map_counts[map_index] {
				if map_counts[map_index] >= MAX_KEYS do return -1
				keys[base + position] = second
				map_counts[map_index] += 1
			}
			timestamps[base + position] = third
		} else if opcode == 2 {
			if first < 0 || first > 1 || second < I32_MIN || second > I32_MAX || third != 0 do return -1
			add_map := int(first)*2
			add_base := add_map * MAX_KEYS
			remove_map := add_map + 1
			remove_base := remove_map * MAX_KEYS
			add_position := 0
			remove_position := 0
			for add_position < map_counts[add_map] && keys[add_base + add_position] != second { add_position += 1 }
			for remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second { remove_position += 1 }
			if add_position < map_counts[add_map] && (remove_position == map_counts[remove_map] ||
				 timestamps[add_base + add_position] > timestamps[remove_base + remove_position]) {
				lookup_mask |= i64(1) << u32(lookup_index)
			}
			lookup_index += 1
		} else if opcode == 3 {
			if first < 0 || first > 1 || second < 0 || second > 1 || third != 0 do return -1
			if first != second {
				for kind in 0..<2 {
					target_map := int(first)*2 + kind
					source_map := int(second)*2 + kind
					target_base := target_map * MAX_KEYS
					source_base := source_map * MAX_KEYS
					for source_position in 0..<map_counts[source_map] {
						key := keys[source_base + source_position]
						timestamp := timestamps[source_base + source_position]
						target_position := 0
						for target_position < map_counts[target_map] && keys[target_base + target_position] != key { target_position += 1 }
						if target_position == map_counts[target_map] {
							if map_counts[target_map] >= MAX_KEYS do return -1
							keys[target_base + target_position] = key
							timestamps[target_base + target_position] = timestamp
							map_counts[target_map] += 1
						} else if timestamp >= timestamps[target_base + target_position] {
							timestamps[target_base + target_position] = timestamp
						}
					}
				}
			}
		} else do return -1
	}
	return lookup_mask
}
