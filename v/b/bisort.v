module bisort

const min_size = 2
const max_size = 1024
const max_nodes = max_size - 1
const modulus = 10000
const multiplier = 31415821
const value_range = 100

struct BisortNode {
mut:
	value int
	left int
	right int
}

struct BisortTree {
mut:
	nodes [max_nodes]BisortNode
	used int
}

fn bisort_multiply(p int, q int) int {
	p_high := p / modulus
	p_low := p % modulus
	q_high := q / modulus
	q_low := q % modulus
	return ((p_low * q_high + p_high * q_low) % modulus) * modulus + p_low * q_low
}

fn bisort_next_random(seed int) int { return bisort_multiply(seed, multiplier) + 1 }

fn bisort_skip_random(seed_value int, count int) int {
	mut seed := seed_value
	for _ in 0 .. count { seed = bisort_next_random(seed) }
	return seed
}

fn bisort_make_tree(mut tree BisortTree, size int, seed_value int) int {
	if size <= 1 { return -1 }
	seed := bisort_next_random(seed_value)
	index := tree.used
	tree.used++
	tree.nodes[index].value = seed % value_range
	half := size / 2
	tree.nodes[index].left = bisort_make_tree(mut tree, half, seed)
	tree.nodes[index].right = bisort_make_tree(mut tree, half, bisort_skip_random(seed, size + 1))
	return index
}

fn bisort_swap_left(mut tree BisortTree, left int, right int, left_left int, right_left int,
	left_value int, right_value int) {
	tree.nodes[right].value = left_value
	tree.nodes[right].left = left_left
	tree.nodes[left].left = right_left
	tree.nodes[left].value = right_value
}

fn bisort_swap_right(mut tree BisortTree, left int, right int, left_right int, right_right int,
	left_value int, right_value int) {
	tree.nodes[right].value = left_value
	tree.nodes[right].right = left_right
	tree.nodes[left].right = right_right
	tree.nodes[left].value = right_value
}

fn bisort_merge(mut tree BisortTree, root int, spill_value int, direction int) int {
	mut spill := spill_value
	mut root_value := tree.nodes[root].value
	mut left := tree.nodes[root].left
	mut right := tree.nodes[root].right
	right_exchange := (root_value > spill) != (direction != 0)
	if right_exchange {
		tree.nodes[root].value = spill
		spill = root_value
	}
	for left >= 0 {
		left_value := tree.nodes[left].value
		left_left := tree.nodes[left].left
		left_right := tree.nodes[left].right
		right_value := tree.nodes[right].value
		right_left := tree.nodes[right].left
		right_right := tree.nodes[right].right
		element_exchange := (left_value > right_value) != (direction != 0)
		if right_exchange {
			if element_exchange {
				bisort_swap_right(mut tree, left, right, left_right, right_right, left_value, right_value)
				left = left_left
				right = right_left
			} else {
				left = left_right
				right = right_right
			}
		} else if element_exchange {
			bisort_swap_left(mut tree, left, right, left_left, right_left, left_value, right_value)
			left = left_right
			right = right_right
		} else {
			left = left_left
			right = right_left
		}
	}
	if tree.nodes[root].left >= 0 {
		left_root := tree.nodes[root].left
		right_root := tree.nodes[root].right
		root_value = tree.nodes[root].value
		tree.nodes[root].value = bisort_merge(mut tree, left_root, root_value, direction)
		spill = bisort_merge(mut tree, right_root, spill, direction)
	}
	return spill
}

fn bisort_sort_tree(mut tree BisortTree, root int, spill_value int, direction int) int {
	mut spill := spill_value
	if tree.nodes[root].left < 0 {
		if (tree.nodes[root].value > spill) != (direction != 0) {
			value := tree.nodes[root].value
			tree.nodes[root].value = spill
			spill = value
		}
		return spill
	}
	left := tree.nodes[root].left
	right := tree.nodes[root].right
	value := tree.nodes[root].value
	tree.nodes[root].value = bisort_sort_tree(mut tree, left, value, direction)
	other_direction := if direction == 0 { 1 } else { 0 }
	spill = bisort_sort_tree(mut tree, right, spill, other_direction)
	return bisort_merge(mut tree, root, spill, direction)
}

fn bisort_checksum(tree &BisortTree, index int, mut position i64, mut sum i64) {
	if index < 0 { return }
	bisort_checksum(tree, tree.nodes[index].left, mut position, mut sum)
	position++
	sum += position * i64(tree.nodes[index].value)
	bisort_checksum(tree, tree.nodes[index].right, mut position, mut sum)
}

@[export: 'bisort']
pub fn bisort(size i64) i64 {
	if size < i64(min_size) || size > i64(max_size) { return -1 }
	mut tree := BisortTree{}
	root := bisort_make_tree(mut tree, int(size), 12345768)
	mut spill := bisort_next_random(245867) % value_range
	spill = bisort_sort_tree(mut tree, root, spill, 0)
	spill = bisort_sort_tree(mut tree, root, spill, 1)
	mut position := i64(0)
	mut sum := i64(0)
	bisort_checksum(&tree, root, mut position, mut sum)
	position++
	return sum + position * i64(spill)
}
