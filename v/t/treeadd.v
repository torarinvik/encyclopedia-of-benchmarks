module treeadd

const max_level = 12
const max_nodes = (1 << max_level) - 1
const addition_passes = 100

struct Node {
	mut:
	value i32
	left int
	right int
}

struct Tree {
	mut:
	nodes [max_nodes]Node
	used int
}

fn allocate_tree(mut tree Tree, level int, lo int, proc_count int) int {
	if level == 0 || tree.used >= max_nodes { return -1 }
	index := tree.used
	tree.used++
	tree.nodes[index].value = 1
	left := allocate_tree(mut tree, level - 1, lo + proc_count / 2, proc_count / 2)
	right := allocate_tree(mut tree, level - 1, lo, proc_count / 2)
	tree.nodes[index].left = left
	tree.nodes[index].right = right
	return index
}

fn tree_add(tree &Tree, index int) i64 {
	if index < 0 { return 0 }
	node := tree.nodes[index]
	return i64(node.value) + tree_add(tree, node.left) + tree_add(tree, node.right)
}

@[export: 'treeadd']
pub fn treeadd(level i64) i64 {
	if level < 0 || level > i64(max_level) { return -1 }
	mut tree := Tree{}
	root := allocate_tree(mut tree, int(level), 0, 4)
	mut result := i64(0)
	for _ in 0 .. addition_passes { result = tree_add(tree, root) }
	return result
}
