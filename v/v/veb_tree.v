module veb_tree

const max_count = 256
const max_input_values = 771
const max_output_bytes = 1024
const max_tree_nodes = 358
const max_clusters = 16

struct VebNode {
	mut:
		universe int
		low_bits int
		cluster_count int
		minimum int
		maximum int
		summary int
		clusters [max_clusters]int
}

struct VebTree {
	mut:
		nodes [max_tree_nodes]VebNode
		next int
}

fn initialize(mut tree VebTree, universe int) int {
	id := tree.next
	tree.next++
	tree.nodes[id].universe = universe
	tree.nodes[id].low_bits = 0
	tree.nodes[id].cluster_count = 0
	tree.nodes[id].minimum = -1
	tree.nodes[id].maximum = 0
	tree.nodes[id].summary = -1
	if universe > 2 {
		mut exponent := 0
		mut remaining := universe
		for remaining > 1 {
			remaining /= 2
			exponent++
		}
		low_bits := exponent / 2
		low_size := 1 << low_bits
		cluster_count := universe / low_size
		tree.nodes[id].low_bits = low_bits
		tree.nodes[id].cluster_count = cluster_count
		summary := initialize(mut tree, cluster_count)
		tree.nodes[id].summary = summary
		for index in 0 .. cluster_count {
			child := initialize(mut tree, low_size)
			tree.nodes[id].clusters[index] = child
		}
	}
	return id
}

fn contains(tree &VebTree, id int, value int) bool {
	node := tree.nodes[id]
	if node.minimum < 0 { return false }
	if node.minimum == value || node.maximum == value { return true }
	if node.universe == 2 { return false }
	low_size := 1 << node.low_bits
	high := value >> node.low_bits
	low := value & (low_size - 1)
	return contains(tree, node.clusters[high], low)
}

fn insert(mut tree VebTree, id int, initial_value int) {
	if contains(&tree, id, initial_value) { return }
	if tree.nodes[id].minimum < 0 {
		tree.nodes[id].minimum = initial_value
		tree.nodes[id].maximum = initial_value
		return
	}
	mut value := initial_value
	if value < tree.nodes[id].minimum {
		old_minimum := tree.nodes[id].minimum
		tree.nodes[id].minimum = value
		value = old_minimum
	}
	if tree.nodes[id].universe > 2 {
		low_size := 1 << tree.nodes[id].low_bits
		high := value >> tree.nodes[id].low_bits
		low := value & (low_size - 1)
		cluster := tree.nodes[id].clusters[high]
		if tree.nodes[cluster].minimum < 0 {
			insert(mut tree, tree.nodes[id].summary, high)
			tree.nodes[cluster].minimum = low
			tree.nodes[cluster].maximum = low
		} else {
			insert(mut tree, cluster, low)
		}
	}
	if value > tree.nodes[id].maximum { tree.nodes[id].maximum = value }
}

fn successor(tree &VebTree, id int, value int) int {
	node := tree.nodes[id]
	if node.minimum < 0 { return -1 }
	if value < node.minimum { return node.minimum }
	if node.universe == 2 { return if value == 0 && node.maximum == 1 { 1 } else { -1 } }
	low_size := 1 << node.low_bits
	high := value >> node.low_bits
	low := value & (low_size - 1)
	cluster := node.clusters[high]
	if tree.nodes[cluster].minimum >= 0 && low < tree.nodes[cluster].maximum {
		next_low := successor(tree, cluster, low)
		if next_low < 0 { return -1 }
		return high * low_size + next_low
	}
	next_cluster := successor(tree, node.summary, high)
	if next_cluster < 0 { return -1 }
	next_minimum := tree.nodes[node.clusters[next_cluster]].minimum
	if next_minimum < 0 { return -1 }
	return next_cluster * low_size + next_minimum
}

fn predecessor(tree &VebTree, id int, value int) int {
	node := tree.nodes[id]
	if node.minimum < 0 || value <= node.minimum { return -1 }
	if value > node.maximum { return node.maximum }
	if node.universe == 2 { return if value == 1 && node.minimum == 0 { 0 } else { -1 } }
	low_size := 1 << node.low_bits
	high := value >> node.low_bits
	low := value & (low_size - 1)
	cluster := node.clusters[high]
	if tree.nodes[cluster].minimum >= 0 && low > tree.nodes[cluster].minimum {
		previous_low := predecessor(tree, cluster, low)
		if previous_low >= 0 { return high * low_size + previous_low }
	}
	previous_cluster := predecessor(tree, node.summary, high)
	if previous_cluster < 0 { return node.minimum }
	previous_maximum := tree.nodes[node.clusters[previous_cluster]].maximum
	if previous_maximum < 0 { return -1 }
	return previous_cluster * low_size + previous_maximum
}

@[export: 'veb_tree']
pub fn veb_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_values + 1 { return -1 }
		if input[0] < 2 || input[0] > max_count || input[1] < 0 || input[1] > max_count ||
			input[2] < 0 || input[2] > max_count { return -1 }
		requested := int(input[0])
		insert_count := int(input[1])
		query_count := int(input[2])
		if length != usize(3 + insert_count + 2 * query_count) { return -1 }
		for index in 0 .. insert_count {
			if input[3 + index] < 0 || input[3 + index] >= i64(requested) { return -1 }
		}
		for index in 0 .. query_count {
			opcode := input[3 + insert_count + 2 * index]
			key := input[4 + insert_count + 2 * index]
			if opcode < 0 || opcode > 4 || key < 0 || key >= i64(requested) { return -1 }
		}
		needed := query_count * 4
		if needed > max_output_bytes { return -1 }
		if output == nil || capacity < usize(needed) { return -2 }
		mut rounded := 1
		for rounded < requested { rounded *= 2 }
		mut tree := VebTree{}
		root := initialize(mut tree, rounded)
		for index in 0 .. insert_count { insert(mut tree, root, int(input[3 + index])) }
		mut result := [max_output_bytes]u8{}
		for index in 0 .. query_count {
			opcode := int(input[3 + insert_count + 2 * index])
			key := int(input[4 + insert_count + 2 * index])
			mut value := 0
			if opcode == 0 {
				if contains(&tree, root, key) { value = 1 }
			} else if opcode == 1 {
				value = successor(&tree, root, key)
			} else if opcode == 2 {
				value = predecessor(&tree, root, key)
			} else if opcode == 3 {
				value = tree.nodes[root].minimum
			} else if tree.nodes[root].minimum >= 0 {
				value = tree.nodes[root].maximum
			}
			bits := if value < 0 { u32(0xffffffff) } else { u32(value) }
			result[4 * index] = u8(bits)
			result[4 * index + 1] = u8(bits >> 8)
			result[4 * index + 2] = u8(bits >> 16)
			result[4 * index + 3] = u8(bits >> 24)
		}
		for index in 0 .. needed { output[index] = result[index] }
		return i64(needed)
	}
}
