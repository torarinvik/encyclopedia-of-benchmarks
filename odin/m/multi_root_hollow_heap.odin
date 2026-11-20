package multi_root_hollow_heap

import "core:c"

MAX_OPERATIONS :: 64
MAX_ITEMS :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(194)

minimum_root :: proc "contextless" (node_count: int, keys: [^]i64, items: [^]int,
		parents: [^]int, alive: [^]bool) -> int {
	best := -1
	for node := 0; node < node_count; node += 1 {
		if alive[node] && parents[node] == -1 && items[node] >= 0 {
			if best < 0 || keys[node] < keys[best] ||
				keys[node] == keys[best] && (items[node] < items[best] ||
				items[node] == items[best] && node < best) {
				best = node
			}
		}
	}
	return best
}

destroy_hollow_roots_and_consolidate :: proc "contextless" (node_count: int,
		keys: [^]i64, items: [^]int, ranks: [^]int, parents: [^]int, alive: [^]bool) {
	for {
		hollow_root := -1
		for node := 0; node < node_count; node += 1 {
			if alive[node] && parents[node] == -1 && items[node] == -1 {
				hollow_root = node
				break
			}
		}
		if hollow_root < 0 do break
		for child := 0; child < node_count; child += 1 {
			if alive[child] && parents[child] == hollow_root { parents[child] = -1 }
		}
		alive[hollow_root] = false
		parents[hollow_root] = -2
	}

	for {
		duplicate_rank := -1
		for first := 0; first < node_count; first += 1 {
			if !alive[first] || parents[first] != -1 || items[first] < 0 do continue
			for second := first+1; second < node_count; second += 1 {
				if alive[second] && parents[second] == -1 && items[second] >= 0 &&
					ranks[second] == ranks[first] &&
					(duplicate_rank < 0 || ranks[first] < duplicate_rank) {
					duplicate_rank = ranks[first]
				}
			}
		}
		if duplicate_rank < 0 do break
		first_root := -1
		second_root := -1
		for node := 0; node < node_count; node += 1 {
			if alive[node] && parents[node] == -1 && items[node] >= 0 && ranks[node] == duplicate_rank {
				if first_root < 0 { first_root = node } else { second_root = node; break }
			}
		}
		if first_root < 0 || second_root < 0 do break
		winner := first_root
		loser := second_root
		if keys[second_root] < keys[first_root] ||
			keys[second_root] == keys[first_root] && (items[second_root] < items[first_root] ||
			items[second_root] == items[first_root] && second_root < first_root) {
			winner = second_root
			loser = first_root
		}
		parents[loser] = winner
		ranks[winner] += 1
	}
}

@(export)
multi_root_hollow_heap :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	operation_count_value := input[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	if length != c.size_t(1+3*operation_count) do return -1

	keys: [MAX_OPERATIONS]i64
	items: [MAX_OPERATIONS]int
	ranks: [MAX_OPERATIONS]int
	parents: [MAX_OPERATIONS]int
	alive: [MAX_OPERATIONS]bool
	item_nodes: [MAX_ITEMS]int
	active: [MAX_ITEMS]bool
	for node := 0; node < MAX_OPERATIONS; node += 1 { items[node] = -1; parents[node] = -2 }
	for item := 0; item < MAX_ITEMS; item += 1 { item_nodes[item] = -1 }

	node_count := 0
	result: i64 = 0
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		offset := 1+3*operation_index
		opcode := input[offset]
		item_value := input[offset+1]
		value := input[offset+2]
		if opcode == 1 {
			if item_value < 0 || item_value >= MAX_ITEMS || value < 0 || value > 1_000_000 do return -1
			item := int(item_value)
			if active[item] || node_count >= MAX_OPERATIONS do return -1
			node := node_count
			node_count += 1
			keys[node] = value
			items[node] = item
			ranks[node] = 0
			parents[node] = -1
			alive[node] = true
			item_nodes[item] = node
			active[item] = true
		} else if opcode == 2 {
			if item_value < 0 || item_value >= MAX_ITEMS || value < 0 || value > 1_000_000 do return -1
			item := int(item_value)
			if !active[item] || node_count >= MAX_OPERATIONS do return -1
			old_node := item_nodes[item]
			if value >= keys[old_node] do return -1
			old_rank := ranks[old_node]
			new_rank := old_rank-2
			if new_rank < 0 { new_rank = 0 }
			items[old_node] = -1
			new_node := node_count
			node_count += 1
			keys[new_node] = value
			items[new_node] = item
			ranks[new_node] = new_rank
			parents[new_node] = -1
			alive[new_node] = true
			for child := 0; child < new_node; child += 1 {
				if alive[child] && parents[child] == old_node && ranks[child] < new_rank { parents[child] = new_node }
			}
			item_nodes[item] = new_node
		} else if opcode == 3 {
			if item_value != 0 || value != 0 do return -1
			node := minimum_root(node_count, &keys[0], &items[0], &parents[0], &alive[0])
			if node < 0 do return -1
			item := items[node]
			active[item] = false
			item_nodes[item] = -1
			items[node] = -1
			result += i64(operation_index+1)*(keys[node]+1)+i64(item)
			destroy_hollow_roots_and_consolidate(node_count, &keys[0], &items[0], &ranks[0], &parents[0], &alive[0])
		} else if opcode == 4 {
			if item_value != 0 || value != 0 do return -1
			node := minimum_root(node_count, &keys[0], &items[0], &parents[0], &alive[0])
			if node < 0 do return -1
			result += i64(operation_index+1)*(keys[node]+1)+i64(items[node])
		} else if opcode == 5 {
			if item_value < 0 || item_value >= MAX_ITEMS || value != 0 do return -1
			item := int(item_value)
			if !active[item] do return -1
			node := item_nodes[item]
			was_minimum := node == minimum_root(node_count, &keys[0], &items[0], &parents[0], &alive[0])
			active[item] = false
			item_nodes[item] = -1
			items[node] = -1
			if was_minimum {
				destroy_hollow_roots_and_consolidate(node_count, &keys[0], &items[0], &ranks[0], &parents[0], &alive[0])
			}
		} else {
			return -1
		}
	}
	return result
}
