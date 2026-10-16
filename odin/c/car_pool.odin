package car_pool

import "core:c"

@(export)
car_pool :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 194 do return -1
	if input[0] < 0 || input[0] > 1000 || input[1] < 0 || input[1] > 64 do return -1
	capacity := i32(input[0])
	trip_count := int(input[1])
	if int(length) != 2 + 3 * trip_count do return -1

	events: [1001]i32
	for trip := 0; trip < trip_count; trip += 1 {
		offset := 2 + 3 * trip
		passengers := input[offset]
		origin := input[offset + 1]
		destination := input[offset + 2]
		if passengers < 1 || passengers > 1000 || origin < 0 || origin >= destination || destination > 1000 do return -1
		events[int(origin)] += i32(passengers)
		events[int(destination)] -= i32(passengers)
	}

	occupants: i32 = 0
	for position := 0; position < 1000; position += 1 {
		occupants += events[position]
		if occupants > capacity do return 0
	}
	return 1
}
