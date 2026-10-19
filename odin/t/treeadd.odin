package treeadd

MAX_LEVEL :: 12
MAX_NODES :: (1 << MAX_LEVEL) - 1
ADDITION_PASSES :: 100

Node :: struct {
	value: i32,
	left: i32,
	right: i32,
}

allocate_tree :: proc(nodes: [^]Node, used: ^int, level, lo, proc_count: i32) -> i32 {
	if level == 0 || used^ >= MAX_NODES do return -1
	index := i32(used^)
	used^ += 1
	nodes[index].value = 1
	left := allocate_tree(nodes, used, level - 1, lo + proc_count / 2, proc_count / 2)
	right := allocate_tree(nodes, used, level - 1, lo, proc_count / 2)
	nodes[index].left = left
	nodes[index].right = right
	return index
}

tree_add :: proc(nodes: [^]Node, index: i32) -> i64 {
	if index < 0 do return 0
	node := nodes[index]
	return i64(node.value) + tree_add(nodes, node.left) + tree_add(nodes, node.right)
}

@(export)
treeadd :: proc "c" (level: i64) -> i64 {
	if level < 0 || level > MAX_LEVEL do return -1
	var nodes: [MAX_NODES]Node
	used := 0
	root := allocate_tree(&nodes[0], &used, i32(level), 0, 4)
	result: i64 = 0
	for _ in 0..<ADDITION_PASSES { result = tree_add(&nodes[0], root) }
	return result
}
