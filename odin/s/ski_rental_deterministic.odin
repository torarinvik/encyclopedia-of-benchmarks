package ski_rental_deterministic

import "core:c"

MAX_INPUT :: 4
MAX_TRIPS :: 32

@(export)
ski_rental_deterministic :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	rent, purchase, trips := input[0], input[1], input[2]
	if length != 3 || rent < 1 || rent > 32 || purchase < 1 || purchase > 64 || trips < 0 || trips > MAX_TRIPS do return -1
	count := int(trips)
	if output == nil || capacity < c.size_t(count) do return -2
	var actions: [MAX_TRIPS]u8
	threshold := purchase / rent
	for trip := 0; trip < count; trip += 1 {
		if i64(trip) < threshold do actions[trip] = 0
		else if i64(trip) == threshold do actions[trip] = 1
		else do actions[trip] = 2
	}
	for trip := 0; trip < count; trip += 1 do output[trip] = actions[trip]
	return i64(count)
}
