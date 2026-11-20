package linear_extension_count

import "core:c"

MAX_N :: 12
MAX_LENGTH :: 14
MAX_STATES :: 4096

@(export)
linear_extension_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 0 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(n+1) do return -1
	full := (1 << n)-1
	var predecessor: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		if input[1+vertex] < 0 || input[1+vertex] > i64(full) do return -1
		predecessor[vertex] = int(input[1+vertex])
	}
	var ways: [MAX_STATES]i64
	ways[0] = 1
	for prefix := 0; prefix <= full; prefix += 1 {
		count := ways[prefix]
		if count == 0 do continue
		for vertex := 0; vertex < n; vertex += 1 {
			bit := 1 << vertex
			if (prefix & bit) == 0 && (predecessor[vertex] & prefix) == predecessor[vertex] {
				ways[prefix | bit] += count
			}
		}
	}
	return ways[full]
}
