package jump_game_ii

import "core:c"

MAX_LENGTH :: 1024

@(export)
jump_game_ii :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 0 || values[index] > i64(length) do return -1
	}
	if length == 1 do return 0
	queue: [MAX_LENGTH]c.size_t = {}
	distance: [MAX_LENGTH]c.size_t = {}
	visited: [MAX_LENGTH]bool = {}
	head := c.size_t(0)
	tail := c.size_t(1)
	queue[0] = 0
	visited[0] = true
	for head < tail {
		cell := queue[head]
		head += 1
		farthest := cell + c.size_t(values[cell])
		if farthest >= length - 1 do return i64(distance[cell] + 1)
		for next := cell + 1; next <= farthest; next += 1 {
			if !visited[next] {
				visited[next] = true
				distance[next] = distance[cell] + 1
				queue[tail] = next
				tail += 1
			}
		}
	}
	return -1
}
