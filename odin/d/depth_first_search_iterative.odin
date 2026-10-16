package depth_first_search_iterative
import "core:c"
MAX_VERTICES :: 64
MAX_EDGES :: 256
MAX_INPUT_LENGTH :: 518
@(export)
depth_first_search_iterative :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	nv, mv, source, target := input[0], input[1], input[2], input[3]
	if nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES || source < 0 || source >= nv do return -1
	m := int(mv)
	if int(length) != 4 + 2 * m do return -1
	for edge := 0; edge < m; edge += 1 {
		left, right := input[4 + 2 * edge], input[5 + 2 * edge]
		if left < 0 || left >= nv || right < 0 || right >= nv do return -1
	}
	var visited: [MAX_VERTICES]bool
	var pending: [MAX_VERTICES]int
	top := 1
	pending[0] = int(source)
	visited[pending[0]] = true
	for top > 0 {
		top -= 1
		current := pending[top]
		if i64(current) == target do return 1
		for edge := 0; edge < m; edge += 1 {
			left, right := input[4 + 2 * edge], input[5 + 2 * edge]
			neighbor: i64 = -1
			if left == i64(current) { neighbor = right } else if right == i64(current) { neighbor = left }
			if neighbor >= 0 {
				index := int(neighbor)
				if !visited[index] {
					visited[index] = true
					pending[top] = index
					top += 1
				}
			}
		}
	}
	return 0
}
