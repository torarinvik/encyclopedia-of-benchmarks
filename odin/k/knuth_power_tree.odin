package knuth_power_tree

import "core:c"

MAX_TARGET :: 127

build_path :: proc(target: int, parent: [^]int, seen: [^]bool, queue: [^]int,
	reverse: [^]int, path: [^]int) -> int {
	if target == 1 {
		path[0] = 1
		return 1
	}
	head, tail := 0, 1
	queue[0] = 1
	seen[1] = true
	for head < tail {
		current := queue[head]
		head += 1
		chain_length := 0
		for node := current; node != 0; node = parent[node] {
			reverse[chain_length] = node
			chain_length += 1
		}
		for offset := 0; offset < chain_length; offset += 1 {
			ancestor := reverse[chain_length-offset-1]
			child := current + ancestor
			if child > target || seen[child] do continue
			seen[child] = true
			parent[child] = current
			if child == target {
				count := 0
				for node := target; node != 0; node = parent[node] {
					path[count] = node
					count += 1
				}
				left, right := 0, count-1
				for left < right {
					path[left], path[right] = path[right], path[left]
					left += 1
					right -= 1
				}
				return count
			}
			queue[tail] = child
			tail += 1
		}
	}
	return 0
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte * 8)) }
}

@(export)
knuth_power_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	if input[0] < 1 || input[0] > MAX_TARGET do return -1
	target := int(input[0])
	parent: [MAX_TARGET+1]int = {}
	seen: [MAX_TARGET+1]bool = {}
	queue: [MAX_TARGET+1]int = {}
	reverse: [MAX_TARGET+1]int = {}
	path: [MAX_TARGET]int = {}
	path_length := build_path(target, &parent[0], &seen[0], &queue[0], &reverse[0], &path[0])
	if path_length == 0 do return -1
	required := c.size_t((path_length + 1) * 8)
	if output == nil || output_capacity < required do return -2
	store_i64_le(output, 0, i64(path_length-1))
	for index := 0; index < path_length; index += 1 {
		store_i64_le(output, 8*(index+1), i64(path[index]))
	}
	return i64(required)
}
