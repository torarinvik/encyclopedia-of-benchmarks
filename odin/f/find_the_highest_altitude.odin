package find_the_highest_altitude

import "core:c"

@(export)
find_the_highest_altitude :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 1 || input[0] < 0 || input[0] > 1024 || int(length) != int(input[0]) + 1 do return -1
	n := int(input[0])
	altitude: i64 = 0; maximum: i64 = 0
	for i := 0; i < n; i += 1 {
		gain := input[i + 1]
		if gain < -2147483648 || gain > 2147483647 do return -1
		altitude += gain
		if altitude > maximum do maximum = altitude
	}
	return maximum
}
