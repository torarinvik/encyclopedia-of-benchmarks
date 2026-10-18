module lww_element_set

const max_operations = 24
const max_keys = 24
const map_count = 4
const max_parseable_input_length = 98
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)

@[export: 'lww_element_set']
pub fn lww_element_set(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_parseable_input_length { return -1 }
		operation_count_value := input[0]
		if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		operation_count := int(operation_count_value)
		if input_length != usize(1 + 4*operation_count) { return -1 }

		mut keys := [map_count * max_keys]i64{}
		mut timestamps := [map_count * max_keys]i64{}
		mut map_counts := [map_count]int{}
		mut lookup_mask := i64(0)
		mut lookup_index := 0

		for operation in 0 .. operation_count {
			offset := 1 + 4*operation
			opcode := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			third := input[offset + 3]
			if opcode == 0 || opcode == 1 {
				if first < 0 || first > 1 || second < i32_min || second > i32_max || third < i32_min || third > i32_max {
					return -1
				}
				map_index := int(first) * 2
				if opcode == 1 { map_index += 1 }
				base := map_index * max_keys
				mut position := 0
				for position < map_counts[map_index] && keys[base + position] != second { position++ }
				if position == map_counts[map_index] {
					if map_counts[map_index] >= max_keys { return -1 }
					keys[base + position] = second
					map_counts[map_index]++
				}
				timestamps[base + position] = third
			} else if opcode == 2 {
				if first < 0 || first > 1 || second < i32_min || second > i32_max || third != 0 { return -1 }
				add_map := int(first) * 2
				add_base := add_map * max_keys
				remove_map := add_map + 1
				remove_base := remove_map * max_keys
				mut add_position := 0
				mut remove_position := 0
				for add_position < map_counts[add_map] && keys[add_base + add_position] != second { add_position++ }
				for remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second { remove_position++ }
				if add_position < map_counts[add_map] && (remove_position == map_counts[remove_map] ||
					timestamps[add_base + add_position] > timestamps[remove_base + remove_position]) {
					lookup_mask |= i64(1) << lookup_index
				}
				lookup_index++
			} else if opcode == 3 {
				if first < 0 || first > 1 || second < 0 || second > 1 || third != 0 { return -1 }
				if first != second {
					for kind in 0 .. 2 {
						target_map := int(first) * 2 + kind
						source_map := int(second) * 2 + kind
						target_base := target_map * max_keys
						source_base := source_map * max_keys
						for source_position in 0 .. map_counts[source_map] {
							key := keys[source_base + source_position]
							timestamp := timestamps[source_base + source_position]
							mut target_position := 0
							for target_position < map_counts[target_map] && keys[target_base + target_position] != key { target_position++ }
							if target_position == map_counts[target_map] {
								if map_counts[target_map] >= max_keys { return -1 }
								keys[target_base + target_position] = key
								timestamps[target_base + target_position] = timestamp
								map_counts[target_map]++
							} else if timestamp >= timestamps[target_base + target_position] {
								timestamps[target_base + target_position] = timestamp
							}
						}
					}
				}
			} else {
				return -1
			}
		}
		return lookup_mask
	}
}
