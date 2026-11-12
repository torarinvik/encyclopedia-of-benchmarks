module vertex_set_path_composite

const max_n = 64
const max_q = 64
const modulus = i64(998244353)
const max_input_values = usize(4 * max_n + 4 * max_q)

struct Affine {
	a i64
	b i64
}

struct Aggregate {
	forward Affine
	backward Affine
}

fn identity() Affine {
	return Affine{a: 1, b: 0}
}

fn compose(after Affine, before Affine) Affine {
	return Affine{
		a: (after.a * before.a) % modulus
		b: (after.a * before.b + after.b) % modulus
	}
}

fn identity_aggregate() Aggregate {
	id := identity()
	return Aggregate{forward: id, backward: id}
}

fn combine(left Aggregate, right Aggregate) Aggregate {
	return Aggregate{
		forward: compose(right.forward, left.forward)
		backward: compose(left.backward, right.backward)
	}
}

fn find_root(mut parent &int, item int) int {
	unsafe {
		mut node := item
		for parent[node] != node {
			parent[node] = parent[parent[node]]
			node = parent[node]
		}
		return node
	}
}

fn update_leaf(mut tree &Aggregate, base int, position int, value Affine) {
	unsafe {
		mut node := base + position
		tree[node] = Aggregate{forward: value, backward: value}
		for node > 1 {
			node /= 2
			tree[node] = combine(tree[node * 2], tree[node * 2 + 1])
		}
	}
}

fn range_query(tree &Aggregate, base int, left_value int, right_value int) Aggregate {
	unsafe {
		mut prefix := identity_aggregate()
		mut suffix := identity_aggregate()
		mut left := left_value + base
		mut right := right_value + base
		for left < right {
			if (left & 1) != 0 {
				prefix = combine(prefix, tree[left])
				left++
			}
			if (right & 1) != 0 {
				right--
				suffix = combine(tree[right], suffix)
			}
			left /= 2
			right /= 2
		}
		return combine(prefix, suffix)
	}
}

fn path_composition(tree &Aggregate, base int, parent &int, depth &int, head &int,
		position &int, from_value int, to_value int) Affine {
	unsafe {
		mut left := identity()
		mut right := identity()
		mut from := from_value
		mut to := to_value
		for head[from] != head[to] {
			if depth[head[from]] >= depth[head[to]] {
				part := range_query(tree, base, position[head[from]], position[from] + 1)
				left = compose(part.backward, left)
				from = parent[head[from]]
			} else {
				part := range_query(tree, base, position[head[to]], position[to] + 1)
				right = compose(right, part.forward)
				to = parent[head[to]]
			}
		}
		if depth[from] >= depth[to] {
			part := range_query(tree, base, position[to], position[from] + 1)
			left = compose(part.backward, left)
		} else {
			part := range_query(tree, base, position[from], position[to] + 1)
			right = compose(right, part.forward)
		}
		return compose(right, left)
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'vertex_set_path_composite']
pub fn vertex_set_path_composite(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 8 || length > max_input_values { return -1 }
	unsafe {
		nv := input[0]
		qv := input[1]
		if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
		n := int(nv)
		q := int(qv)
		if length != usize(4 * n + 4 * q) { return -1 }

		mut values := [max_n]Affine{}
		for vertex in 0 .. n {
			a := input[2 + 2 * vertex]
			b := input[3 + 2 * vertex]
			if a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			values[vertex] = Affine{a: a, b: b}
		}
		mut adjacent := [max_n * max_n]bool{}
		mut dsu_parent := [max_n]int{}
		mut dsu_size := [max_n]int{}
		for vertex in 0 .. n {
			dsu_parent[vertex] = vertex
			dsu_size[vertex] = 1
		}
		edge_start := 2 + 2 * n
		for edge in 0 .. (n - 1) {
			offset := edge_start + 2 * edge
			lv := input[offset]
			rv := input[offset + 1]
			if lv < 0 || lv >= nv || rv < 0 || rv >= nv || lv == rv { return -1 }
			left := int(lv)
			right := int(rv)
			mut root_left := find_root(&dsu_parent[0], left)
			mut root_right := find_root(&dsu_parent[0], right)
			if root_left == root_right { return -1 }
			if dsu_size[root_left] < dsu_size[root_right] {
				root_left, root_right = root_right, root_left
			}
			dsu_parent[root_right] = root_left
			dsu_size[root_left] += dsu_size[root_right]
			adjacent[left * max_n + right] = true
			adjacent[right * max_n + left] = true
		}

		operation_start := edge_start + 2 * (n - 1)
		for query in 0 .. q {
			offset := operation_start + 4 * query
			kind := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			third := input[offset + 3]
			if kind == 0 {
				if first < 0 || first >= nv || second < 1 || second >= modulus || third < 0 || third >= modulus { return -1 }
			} else if kind == 1 {
				if first < 0 || first >= nv || second < 0 || second >= nv || third < 0 || third >= modulus { return -1 }
			} else { return -1 }
		}

		mut parent := [max_n]int{}
		mut depth := [max_n]int{}
		mut subtree := [max_n]int{}
		mut heavy := [max_n]int{init: max_n}
		mut order := [max_n]int{}
		mut stack := [max_n]int{}
		mut order_count := 1
		mut top := 1
		parent[0] = 0
		subtree[0] = 1
		stack[0] = 0
		order[0] = 0
		for top > 0 {
			top--
			vertex := stack[top]
			for neighbor in 0 .. n {
				if !adjacent[vertex * max_n + neighbor] || neighbor == parent[vertex] { continue }
				parent[neighbor] = vertex
				depth[neighbor] = depth[vertex] + 1
				subtree[neighbor] = 1
				heavy[neighbor] = max_n
				order[order_count] = neighbor
				order_count++
				stack[top] = neighbor
				top++
			}
		}
		for index := order_count; index > 1; index-- {
			vertex := order[index - 1]
			p := parent[vertex]
			subtree[p] += subtree[vertex]
			if heavy[p] == max_n || subtree[vertex] > subtree[heavy[p]] ||
				(subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p]) { heavy[p] = vertex }
		}

		mut head := [max_n]int{}
		mut position := [max_n]int{}
		mut chain_vertex := [max_n]int{}
		mut chain_head := [max_n]int{}
		mut chain_count := 1
		mut timer := 0
		chain_vertex[0] = 0
		chain_head[0] = 0
		for chain_count > 0 {
			chain_count--
			mut vertex := chain_vertex[chain_count]
			current_head := chain_head[chain_count]
			for vertex != max_n {
				head[vertex] = current_head
				position[vertex] = timer
				timer++
				for child in 0 .. n {
					if adjacent[vertex * max_n + child] && parent[child] == vertex && child != heavy[vertex] {
						chain_vertex[chain_count] = child
						chain_head[chain_count] = child
						chain_count++
					}
				}
				vertex = heavy[vertex]
			}
		}

		mut base := 1
		for base < n { base *= 2 }
		mut tree := [2 * max_n]Aggregate{}
		for node in 0 .. (2 * base) { tree[node] = identity_aggregate() }
		for vertex in 0 .. n { update_leaf(&tree[0], base, position[vertex], values[vertex]) }
		mut answers := [max_q]i64{}
		mut answer_count := 0
		for query in 0 .. q {
			offset := operation_start + 4 * query
			kind := input[offset]
			first := int(input[offset + 1])
			second := input[offset + 2]
			third := input[offset + 3]
			if kind == 0 {
				values[first] = Affine{a: second, b: third}
				update_leaf(&tree[0], base, position[first], values[first])
			} else {
				combined := path_composition(&tree[0], base, &parent[0], &depth[0], &head[0], &position[0], first, int(second))
				answers[answer_count] = (combined.a * third + combined.b) % modulus
				answer_count++
			}
		}
		required := answer_count * 8
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		for index in 0 .. answer_count { store_i64_le(mut output, 8 * index, answers[index]) }
		return i64(required)
	}
}
