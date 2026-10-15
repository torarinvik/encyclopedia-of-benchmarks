package keys_and_rooms

import "core:c"

MAX_ROOMS :: 1000
MAX_INPUT_LENGTH :: 100001

// Return whether every room is reachable from room zero.
@(export)
keys_and_rooms :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	if values[0] < 2 || values[0] > MAX_ROOMS do return -1
	room_count := int(values[0])
	starts: [MAX_ROOMS]int
	degrees: [MAX_ROOMS]int
	cursor := 1

	for room := 0; room < room_count; room += 1 {
		if cursor >= int(length) do return -1
		count_value := values[cursor]
		cursor += 1
		if count_value < 0 || count_value > i64(room_count) do return -1
		degree := int(count_value)
		if degree > int(length)-cursor do return -1
		starts[room] = cursor
		degrees[room] = degree
		for edge := 0; edge < degree; edge += 1 {
			key := values[cursor+edge]
			if key < 0 || key >= i64(room_count) do return -1
		}
		cursor += degree
	}
	if cursor != int(length) do return -1

	visited: [MAX_ROOMS]bool
	stack: [MAX_ROOMS]int
	for room := 0; room < room_count; room += 1 { visited[room] = false }
	stack[0] = 0
	visited[0] = true
	stack_size := 1
	reached := 0
	for stack_size > 0 {
		stack_size -= 1
		room := stack[stack_size]
		reached += 1
		for edge := 0; edge < degrees[room]; edge += 1 {
			key := int(values[starts[room]+edge])
			if !visited[key] {
				visited[key] = true
				stack[stack_size] = key
				stack_size += 1
			}
		}
	}
	if reached == room_count do return 1
	return 0
}
