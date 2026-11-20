module ternary_search_trie

const max_operations = 64
const max_key_length = 6
const record_width = 9
const max_input_values = 577
const max_parseable_input_values = 578
const max_nodes = 384

struct Tst_node {
mut:
	character i64
	left int
	middle int
	right int
	value i64
	present bool
}

fn put_node(mut nodes [max_nodes + 1]Tst_node, node_id int,
	key [max_key_length]i64, length int, depth int, value i64,
	mut old_value i64, mut size int, mut node_count int) int {
	mut current := node_id
	if current == 0 {
		node_count++
		current = node_count
		nodes[current].character = key[depth]
	}
	if key[depth] < nodes[current].character {
		nodes[current].left = put_node(mut nodes, nodes[current].left, key, length,
			depth, value, mut old_value, mut size, mut node_count)
	} else if key[depth] > nodes[current].character {
		nodes[current].right = put_node(mut nodes, nodes[current].right, key, length,
			depth, value, mut old_value, mut size, mut node_count)
	} else if depth + 1 < length {
		nodes[current].middle = put_node(mut nodes, nodes[current].middle, key,
			length, depth + 1, value, mut old_value, mut size, mut node_count)
	} else {
		old_value = if nodes[current].present { nodes[current].value } else { i64(0) }
		if !nodes[current].present {
			size++
		}
		nodes[current].value = value
		nodes[current].present = true
	}
	return current
}

fn find_node(nodes [max_nodes + 1]Tst_node, node_id int,
	key [max_key_length]i64, length int) int {
	mut current := node_id
	mut depth := 0
	for current != 0 {
		if key[depth] < nodes[current].character {
			current = nodes[current].left
		} else if key[depth] > nodes[current].character {
			current = nodes[current].right
		} else if depth + 1 == length {
			return current
		} else {
			current = nodes[current].middle
			depth++
		}
	}
	return 0
}

fn delete_node(mut nodes [max_nodes + 1]Tst_node, node_id int,
	key [max_key_length]i64, length int, depth int,
	mut removed i64, mut size int) int {
	if node_id == 0 {
		return 0
	}
	if key[depth] < nodes[node_id].character {
		nodes[node_id].left = delete_node(mut nodes, nodes[node_id].left, key,
			length, depth, mut removed, mut size)
	} else if key[depth] > nodes[node_id].character {
		nodes[node_id].right = delete_node(mut nodes, nodes[node_id].right, key,
			length, depth, mut removed, mut size)
	} else if depth + 1 < length {
		nodes[node_id].middle = delete_node(mut nodes, nodes[node_id].middle, key,
			length, depth + 1, mut removed, mut size)
	} else if nodes[node_id].present {
		removed = nodes[node_id].value
		nodes[node_id].value = 0
		nodes[node_id].present = false
		size--
	}
	if !nodes[node_id].present && nodes[node_id].left == 0
		&& nodes[node_id].middle == 0 && nodes[node_id].right == 0 {
		return 0
	}
	return node_id
}

fn count_nodes(nodes [max_nodes + 1]Tst_node, node_id int) int {
	if node_id == 0 {
		return 0
	}
	mut present := 0
	if nodes[node_id].present {
		present = 1
	}
	return present + count_nodes(nodes, nodes[node_id].left) +
		count_nodes(nodes, nodes[node_id].middle) + count_nodes(nodes, nodes[node_id].right)
}

fn count_matches(nodes [max_nodes + 1]Tst_node, node_id int,
	pattern [max_key_length]i64, length int, depth int) int {
	if node_id == 0 {
		return 0
	}
	token := pattern[depth]
	if token == 46 {
		mut here := 0
		if depth + 1 == length {
			if nodes[node_id].present {
				here = 1
			}
		} else {
			here = count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1)
		}
		return count_matches(nodes, nodes[node_id].left, pattern, length, depth) + here +
			count_matches(nodes, nodes[node_id].right, pattern, length, depth)
	}
	if token < nodes[node_id].character {
		return count_matches(nodes, nodes[node_id].left, pattern, length, depth)
	}
	if token > nodes[node_id].character {
		return count_matches(nodes, nodes[node_id].right, pattern, length, depth)
	}
	if depth + 1 == length {
		if nodes[node_id].present {
			return 1
		}
		return 0
	}
	return count_matches(nodes, nodes[node_id].middle, pattern, length, depth + 1)
}

fn valid_input(input &i64, length usize) int {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_values {
			return -1
		}
		if input[0] < 0 || input[0] > max_operations {
			return -1
		}
		operation_count := int(input[0])
		if length != usize(1 + operation_count * record_width) {
			return -1
		}
		for operation in 0 .. operation_count {
			base := 1 + operation * record_width
			opcode, key_length := input[base], input[base + 1]
			if opcode < 0 || opcode > 6 || key_length < 0 || key_length > max_key_length {
				return -1
			}
			if (opcode <= 2 && key_length == 0) || (opcode == 6 && key_length != 0) {
				return -1
			}
			for index in 0 .. max_key_length {
				character := input[base + 2 + index]
				if index < int(key_length) {
					if !((character >= 97 && character <= 122) ||
						(opcode == 5 && character == 46)) {
						return -1
					}
				} else if character != 0 {
					return -1
				}
			}
			value := input[base + record_width - 1]
			if opcode == 0 {
				if value < 1 || value > 65535 {
					return -1
				}
			} else if value != 0 {
				return -1
			}
		}
		return operation_count
	}
}

@[export: 'ternary_search_trie']
pub fn ternary_search_trie(input &i64, length usize) i64 {
	operation_count := valid_input(input, length)
	if operation_count < 0 {
		return -1
	}
	mut nodes := [max_nodes + 1]Tst_node{}
	mut node_count := 0
	mut root := 0
	mut size := 0
	mut total := i64(0)
	unsafe {
		for operation in 0 .. operation_count {
			base := 1 + operation * record_width
			opcode, key_length := input[base], int(input[base + 1])
			mut key := [max_key_length]i64{}
			for index in 0 .. max_key_length {
				key[index] = input[base + 2 + index]
			}
			value := input[base + record_width - 1]
			mut observed := i64(0)
			if opcode == 0 {
				root = put_node(mut nodes, root, key, key_length, 0, value,
					mut observed, mut size, mut node_count)
			} else if opcode == 1 {
				found := find_node(nodes, root, key, key_length)
				if found != 0 && nodes[found].present {
					observed = nodes[found].value
				}
			} else if opcode == 2 {
				root = delete_node(mut nodes, root, key, key_length, 0, mut observed, mut size)
			} else if opcode == 3 {
				mut current := root
				mut depth := 0
				for current != 0 && depth < key_length {
					if key[depth] < nodes[current].character {
						current = nodes[current].left
					} else if key[depth] > nodes[current].character {
						current = nodes[current].right
					} else {
						depth++
						if nodes[current].present {
							observed = i64(depth)
						}
						current = nodes[current].middle
					}
				}
			} else if opcode == 4 {
				if key_length == 0 {
					observed = i64(size)
				} else {
					found := find_node(nodes, root, key, key_length)
					if found != 0 {
						mut count := 0
						if nodes[found].present {
							count = 1
						}
						observed = i64(count + count_nodes(nodes, nodes[found].middle))
					}
				}
			} else if opcode == 5 && key_length != 0 {
				observed = i64(count_matches(nodes, root, key, key_length, 0))
			} else if opcode == 6 {
				observed = i64(size)
			}
			total += i64(operation + 1) * observed
		}
	}
	return total
}
