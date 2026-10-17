package search_singly_linked_list_recursion

import "core:c"

MAX_NODES :: 64
I32_MIN :: i64(-2_147_483_648)
I32_MAX :: i64(2_147_483_647)

Node :: struct { value: i32, next: int }

search_recursion :: proc(nodes: []Node, current: int, key: i32) -> bool {
	if current < 0 do return false
	return nodes[current].value == key || search_recursion(nodes, nodes[current].next, key)
}

@(export)
search_singly_linked_list_recursion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_NODES + 2 do return -1
	count_value := input[0]
	key_value := input[1]
	if count_value < 0 || count_value > MAX_NODES || length != c.size_t(count_value + 2) || key_value < I32_MIN || key_value > I32_MAX do return -1
	count := int(count_value)
	nodes := make([]Node, count)
	for index := 0; index < count; index += 1 {
		value := input[index + 2]
		if value < I32_MIN || value > I32_MAX do return -1
		nodes[index] = Node{value = i32(value), next = if index + 1 < count then index + 1 else -1}
	}
	return if search_recursion(nodes, if count == 0 then -1 else 0, i32(key_value)) then 1 else 0
}
