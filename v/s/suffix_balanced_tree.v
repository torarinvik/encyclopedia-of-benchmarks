module suffix_balanced_tree

const max_text = 32
const max_input = 33
const tag_limit = u64(1) << 62

struct Tree {
mut:
	text [max_text]i64
	left [max_text]int
	right [max_text]int
	size [max_text]int
	tag [max_text]u64
	buffer [max_text]int
	answer [max_text]int
	buffered int
}

fn node_size(tree &Tree, node int) int {
	if node < 0 { return 0 }
	return tree.size[node]
}
fn suffix_less(tree &Tree, x int, y int, n int) bool {
	if tree.text[x] != tree.text[y] { return tree.text[x] < tree.text[y] }
	next_x := if x + 1 < n { tree.tag[x + 1] } else { u64(0) }
	next_y := if y + 1 < n { tree.tag[y + 1] } else { u64(0) }
	return next_x < next_y
}
fn flatten(mut tree &Tree, root int) {
	if root < 0 { return }
	flatten(mut tree, tree.left[root])
	tree.buffer[tree.buffered] = root
	tree.buffered++
	flatten(mut tree, tree.right[root])
}
fn build_balanced(mut tree &Tree, lo int, hi int, low u64, high u64) int {
	if lo >= hi { return -1 }
	mid := lo + (hi - lo) / 2
	root := tree.buffer[mid]
	tag := low + (high - low) / 2
	tree.tag[root] = tag
	left := build_balanced(mut tree, lo, mid, low, tag)
	right := build_balanced(mut tree, mid + 1, hi, tag, high)
	tree.left[root] = left
	tree.right[root] = right
	tree.size[root] = 1 + node_size(tree, left) + node_size(tree, right)
	return root
}
fn rebuild(mut tree &Tree, root int, low u64, high u64) int {
	tree.buffered = 0
	flatten(mut tree, root)
	return build_balanced(mut tree, 0, tree.buffered, low, high)
}
fn insert_suffix(mut tree &Tree, root int, pos int, n int, low u64, high u64) int {
	if root < 0 {
		tree.left[pos] = -1
		tree.right[pos] = -1
		tree.size[pos] = 1
		tree.tag[pos] = low + (high - low) / 2
		return pos
	}
	middle := tree.tag[root]
	if suffix_less(tree, pos, root, n) {
		child := tree.left[root]
		inserted := insert_suffix(mut tree, child, pos, n, low, middle)
		tree.left[root] = inserted
	} else {
		child := tree.right[root]
		inserted := insert_suffix(mut tree, child, pos, n, middle, high)
		tree.right[root] = inserted
	}
	left_size := node_size(tree, tree.left[root])
	right_size := node_size(tree, tree.right[root])
	tree.size[root] = 1 + left_size + right_size
	if 4 * max(left_size, right_size) >= 3 * tree.size[root] { return rebuild(mut tree, root, low, high) }
	return root
}
fn inorder(mut tree &Tree, root int, mut count int) {
	if root < 0 { return }
	inorder(mut tree, tree.left[root], mut count)
	tree.answer[count] = root
	count++
	inorder(mut tree, tree.right[root], mut count)
}
fn store_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'suffix_balanced_tree']
pub fn suffix_balanced_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		nv := input[0]
		if nv < 0 || nv > max_text || length != usize(1 + nv) { return -1 }
		n := int(nv)
		for i in 0 .. n { if input[1 + i] < 0 || input[1 + i] > 255 { return -1 } }
		required := 8 * n
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		mut tree := Tree{}
		for i in 0 .. n { tree.text[i] = input[1 + i] }
		mut root := -1
		for pos := n - 1; pos >= 0; pos-- { root = insert_suffix(mut tree, root, pos, n, u64(0), tag_limit) }
		mut count := 0
		inorder(mut tree, root, mut count)
		for i in 0 .. count { store_le(mut output, 8 * i, i64(tree.answer[i])) }
		return i64(required)
	}
}
