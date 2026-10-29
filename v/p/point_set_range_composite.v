module point_set_range_composite

const modulus = i64(998244353)
const max_n = 16
const max_operations = 32
const max_input_length = usize(162)
const tree_capacity = 64

struct AffineMap {
	a i64
	b i64
}

struct SegmentTree {
	mut:
	nodes [tree_capacity]AffineMap
}

fn identity_map() AffineMap {
	return AffineMap{a: 1, b: 0}
}

fn compose(left AffineMap, right AffineMap) AffineMap {
	return AffineMap{
		a: (right.a * left.a) % modulus
		b: (right.a * left.b + right.b) % modulus
	}
}

@[export: 'point_set_range_composite']
pub fn point_set_range_composite(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { values[0] }
	q_value := unsafe { values[1] }
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_operations { return -1 }
	n := int(n_value)
	q := int(q_value)
	if length != usize(2 + 2 * n + 4 * q) { return -1 }

	for i in 0 .. n {
		a := unsafe { values[2 + 2 * i] }
		b := unsafe { values[3 + 2 * i] }
		if a < 0 || a >= modulus || b < 0 || b >= modulus { return -1 }
	}

	mut base := 1
	for base < n { base *= 2 }
	mut tree := SegmentTree{}
	for i in 0 .. tree_capacity { tree.nodes[i] = identity_map() }
	for i in 0 .. n {
		tree.nodes[base + i] = AffineMap{
			a: unsafe { values[2 + 2 * i] }
			b: unsafe { values[3 + 2 * i] }
		}
	}
	mut node := base
	for node > 1 {
		node--
		tree.nodes[node] = compose(tree.nodes[2 * node], tree.nodes[2 * node + 1])
	}

	mut checksum := i64(0)
	mut query_number := i64(0)
	mut cursor := 2 + 2 * n
	for _ in 0 .. q {
		opcode := unsafe { values[cursor] }
		first := unsafe { values[cursor + 1] }
		second := unsafe { values[cursor + 2] }
		third := unsafe { values[cursor + 3] }
		cursor += 4
		if opcode == 0 {
			if first < 0 || first >= n_value || second < 0 || second >= modulus || third < 0 || third >= modulus { return -1 }
			mut node := base + int(first)
			tree.nodes[node] = AffineMap{a: second, b: third}
			for node > 1 {
				node /= 2
				tree.nodes[node] = compose(tree.nodes[2 * node], tree.nodes[2 * node + 1])
			}
		} else if opcode == 1 {
			if first < 0 || first > second || second > n_value || third < 0 || third >= modulus { return -1 }
			mut left_index := base + int(first)
			mut right_index := base + int(second)
			mut left := identity_map()
			mut right := identity_map()
			for left_index < right_index {
				if left_index & 1 == 1 {
					left = compose(left, tree.nodes[left_index])
					left_index++
				}
				if right_index & 1 == 1 {
					right_index--
					right = compose(tree.nodes[right_index], right)
				}
				left_index /= 2
				right_index /= 2
			}
			combined := compose(left, right)
			answer := (combined.a * third + combined.b) % modulus
			query_number++
			checksum = (checksum + query_number * answer) % modulus
		} else {
			return -1
		}
	}
	if cursor != length { return -1 }
	return checksum
}
