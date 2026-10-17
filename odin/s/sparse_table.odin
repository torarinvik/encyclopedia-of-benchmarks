package sparse_table

import "core:c"

MAX_N :: 12345
MAX_LEVELS :: 14
MAX_INPUT_LENGTH :: c.size_t(12347)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(12348)

sparse_table :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n64 := input[0]
	if n64 < 1 || n64 > 12344 do return -1
	n := int(n64)
	if length != c.size_t(n + 3) || length > MAX_INPUT_LENGTH do return -1
	left64, right64 := input[n+1], input[n+2]
	if left64 < 0 || right64 < left64 || right64 >= n64 do return -1
	left, right := int(left64), int(right64)

	var values: [MAX_N]i64
	for index in 0 ..< n { values[index] = input[index+1] }
	var logs: [MAX_N+1]int
	for size := 2; size <= n; size += 1 { logs[size] = logs[size/2] + 1 }
	var table: [MAX_LEVELS*MAX_N]i32
	for index in 0 ..< n { table[index] = i32(index) }
	for level := 1; level <= logs[n]; level += 1 {
		span := 1 << level
		half := span >> 1
		for index := 0; index+span <= n; index += 1 {
			first := int(table[(level-1)*MAX_N+index])
			second := int(table[(level-1)*MAX_N+index+half])
			if values[first] <= values[second] {
				table[level*MAX_N+index] = i32(first)
			} else {
				table[level*MAX_N+index] = i32(second)
			}
		}
	}
	query_length := right-left+1
	level := logs[query_length]
	span := 1 << level
	first := int(table[level*MAX_N+left])
	second := int(table[level*MAX_N+right-span+1])
	if values[first] <= values[second] { return i64(first) }
	return i64(second)
}
