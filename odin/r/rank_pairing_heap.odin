package rank_pairing_heap

import "core:c"

MAX_OPERATIONS :: 64
MAX_ITEMS :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(194)

rank_of :: proc "contextless" (node: int, ranks: [^]int) -> int {
	if node < 0 do return -1
	return ranks[node]
}

minimum_root :: proc "contextless" (node_count: int, keys: [^]i64, items: [^]int,
		parents: [^]int, alive: [^]bool) -> int {
	best := -1
	for node := 0; node < node_count; node += 1 {
		if alive[node] && parents[node] == -1 {
			if best < 0 || keys[node] < keys[best] ||
				keys[node] == keys[best] && (items[node] < items[best] ||
				items[node] == items[best] && node < best) {
				best = node
			}
		}
	}
	return best
}

fair_link :: proc "contextless" (first, second: int, keys: [^]i64, items: [^]int,
		left: [^]int, right: [^]int, ranks: [^]int, parents: [^]int) {
	winner := first
	loser := second
	if keys[second] < keys[first] || keys[second] == keys[first] &&
		(items[second] < items[first] || items[second] == items[first] && second < first) {
		winner = second
		loser = first
	}
	old_left := left[winner]
	left[winner] = loser
	parents[loser] = winner
	right[loser] = old_left
	if old_left >= 0 { parents[old_left] = loser }
	ranks[winner] += 1
}

consolidate_fair_roots :: proc "contextless" (node_count: int, keys: [^]i64, items: [^]int,
		left: [^]int, right: [^]int, ranks: [^]int, parents: [^]int, alive: [^]bool) {
	for {
		duplicate_rank := -1
		for first := 0; first < node_count; first += 1 {
			if !alive[first] || parents[first] != -1 do continue
			for second := first+1; second < node_count; second += 1 {
				if alive[second] && parents[second] == -1 && ranks[second] == ranks[first] &&
					(duplicate_rank < 0 || ranks[first] < duplicate_rank) {
					duplicate_rank = ranks[first]
				}
			}
		}
		if duplicate_rank < 0 do break
		first_root := -1
		second_root := -1
		for node := 0; node < node_count; node += 1 {
			if alive[node] && parents[node] == -1 && ranks[node] == duplicate_rank {
				if first_root < 0 { first_root = node } else { second_root = node; break }
			}
		}
		if first_root < 0 || second_root < 0 do break
		fair_link(first_root, second_root, keys, items, left, right, ranks, parents)
	}
}

@(export)
rank_pairing_heap :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	operation_count_value := input[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	if length != c.size_t(1+3*operation_count) do return -1

	keys: [MAX_OPERATIONS]i64
	items: [MAX_OPERATIONS]int
	ranks: [MAX_OPERATIONS]int
	left: [MAX_OPERATIONS]int
	right: [MAX_OPERATIONS]int
	parents: [MAX_OPERATIONS]int
	alive: [MAX_OPERATIONS]bool
	item_nodes: [MAX_ITEMS]int
	active: [MAX_ITEMS]bool
	for node := 0; node < MAX_OPERATIONS; node += 1 {
		items[node] = -1
		left[node] = -1
		right[node] = -1
		parents[node] = -2
	}
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
			left[node] = -1
			right[node] = -1
			parents[node] = -1
			alive[node] = true
			item_nodes[item] = node
			active[item] = true
		} else if opcode == 2 {
			if item_value < 0 || item_value >= MAX_ITEMS || value < 0 || value > 1_000_000 do return -1
			item := int(item_value)
			if !active[item] do return -1
			node := item_nodes[item]
			if value >= keys[node] do return -1
			keys[node] = value
			if parents[node] >= 0 {
				old_parent := parents[node]
				next_sibling := right[node]
				if left[old_parent] == node { left[old_parent] = next_sibling } else { right[old_parent] = next_sibling }
				if next_sibling >= 0 { parents[next_sibling] = old_parent }
				parents[node] = -1
				right[node] = -1
				ranks[node] = rank_of(left[node], &ranks[0])+1

				ancestor := old_parent
				for ancestor >= 0 {
					if parents[ancestor] < 0 {
						ranks[ancestor] = rank_of(left[ancestor], &ranks[0])+1
						break
					}
					left_rank := rank_of(left[ancestor], &ranks[0])
					right_rank := rank_of(right[ancestor], &ranks[0])
					new_rank := left_rank+1
					if left_rank != right_rank {
						new_rank = left_rank
						if right_rank > new_rank { new_rank = right_rank }
					}
					if new_rank >= ranks[ancestor] do break
					ranks[ancestor] = new_rank
					ancestor = parents[ancestor]
				}
			}
		} else if opcode == 3 {
			if item_value != 0 || value != 0 do return -1
			node := minimum_root(node_count, &keys[0], &items[0], &parents[0], &alive[0])
			if node < 0 do return -1
			removed_item := items[node]
			result += i64(operation_index+1)*(keys[node]+1)+i64(removed_item)
			active[removed_item] = false
			item_nodes[removed_item] = -1
			child := left[node]
			for child >= 0 {
				next_sibling := right[child]
				right[child] = -1
				parents[child] = -1
				ranks[child] = rank_of(left[child], &ranks[0])+1
				child = next_sibling
			}
			alive[node] = false
			parents[node] = -2
			left[node] = -1
			right[node] = -1
			items[node] = -1
			consolidate_fair_roots(node_count, &keys[0], &items[0], &left[0], &right[0], &ranks[0], &parents[0], &alive[0])
		} else if opcode == 4 {
			if item_value != 0 || value != 0 do return -1
			node := minimum_root(node_count, &keys[0], &items[0], &parents[0], &alive[0])
			if node < 0 do return -1
			result += i64(operation_index+1)*(keys[node]+1)+i64(items[node])
		} else {
			return -1
		}
	}
	return result
}
