const max_nodes = 64
const i32_min = i64(-2147483648)
const i32_max = i64(2147483647)

struct Node {
	value i32
	next int
}

fn search_recursion(nodes []Node, current int, key i32) bool {
	if current < 0 { return false }
	return nodes[current].value == key || search_recursion(nodes, nodes[current].next, key)
}

@[export: 'search_singly_linked_list_recursion']
pub fn search_singly_linked_list_recursion(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_nodes + 2 { return -1 }
	unsafe {
		count_value := input[0]
		key_value := input[1]
		if count_value < 0 || count_value > max_nodes || length != usize(count_value + 2) || key_value < i32_min || key_value > i32_max { return -1 }
		count := int(count_value)
		mut nodes := []Node{len: count}
		for index in 0 .. count {
			value := input[index + 2]
			if value < i32_min || value > i32_max { return -1 }
			nodes[index] = Node{value: i32(value), next: if index + 1 < count { index + 1 } else { -1 }}
		}
		return if search_recursion(nodes, if count == 0 { -1 } else { 0 }, i32(key_value)) { 1 } else { 0 }
	}
}
