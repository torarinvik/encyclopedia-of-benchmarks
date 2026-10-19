package stanford_treesort

import "core:c"

MIN_RUNS :: i64(1)
MAX_RUNS :: i64(100)
ELEMENT_COUNT :: 5000
MAX_OUTPUT_BYTES :: 700
Tree_Node :: struct { value: i32, left: i32, right: i32 }

next_random :: proc(seed: ^i64) -> i32 {
	seed^ = (seed^ * 1309 + 13849) % 65536
	return i32(seed^)
}
validate_tree :: proc(nodes: ^[ELEMENT_COUNT]Tree_Node, root: int) -> bool {
	node := nodes[root]
	if node.left != -1 { child := nodes[int(node.left)]; if child.value <= node.value || !validate_tree(nodes, int(node.left)) do return false }
	if node.right != -1 { child := nodes[int(node.right)]; if child.value >= node.value || !validate_tree(nodes, int(node.right)) do return false }
	return true
}
build_and_check_pass :: proc(selected_run: int) -> (i32, bool) {
	var values: [ELEMENT_COUNT]i32
	var nodes: [ELEMENT_COUNT]Tree_Node
	seed: i64 = 74755
	for index := 0; index < ELEMENT_COUNT; index += 1 {
		temp := next_random(&seed)
		values[index] = temp - (temp / 100000) * 100000 - 50000
	}
	nodes[0] = Tree_Node{values[0], -1, -1}
	used := 1
	for index := 1; index < ELEMENT_COUNT; index += 1 {
		current := 0
		for {
			if values[index] > nodes[current].value {
				if nodes[current].left == -1 { nodes[current].left = i32(used); nodes[used] = Tree_Node{values[index], -1, -1}; used += 1; break }
				current = int(nodes[current].left)
			} else if values[index] < nodes[current].value {
				if nodes[current].right == -1 { nodes[current].right = i32(used); nodes[used] = Tree_Node{values[index], -1, -1}; used += 1; break }
				current = int(nodes[current].right)
			} else { break }
		}
	}
	return values[selected_run+1], validate_tree(&nodes, 0)
}
append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text { buffer[used^] = byte; used^ += 1 }
}
append_integer :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: i32) {
	remaining := value
	if remaining < 0 { buffer[used^] = u8('-'); used^ += 1; remaining = -remaining }
	var reversed: [12]u8
	count := 0
	for { reversed[count] = u8('0') + u8(remaining%10); count += 1; remaining /= 10; if remaining == 0 do break }
	for count > 0 { count -= 1; buffer[used^] = reversed[count]; used^ += 1 }
}
@(export)
stanford_treesort :: proc "c" (runs: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if runs < MIN_RUNS || runs > MAX_RUNS do return -1
	if output == nil do return -2
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	for run := 0; run < int(runs); run += 1 {
		value, valid := build_and_check_pass(run)
		append_integer(&staged, &used, value); append_text(&staged, &used, "\n")
		if !valid { append_text(&staged, &used, " Error in Tree.\n") }
	}
	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
