package skew_binomial_queue

import "core:c"

MAX_OPERATIONS :: 64
MAX_ITEMS :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(194)
MAX_RANK_BUCKETS :: MAX_OPERATIONS+1

less_node :: proc "contextless" (first, second: int, keys: [^]i64,
		serials: [^]int, items: [^]int) -> bool {
	return keys[first] < keys[second] || keys[first] == keys[second] &&
		(serials[first] < serials[second] || serials[first] == serials[second] &&
		(items[first] < items[second] || items[first] == items[second] && first < second))
}

roots_before :: proc "contextless" (first, second: int, ranks: [^]int, serials: [^]int) -> bool {
	return ranks[first] < ranks[second] || ranks[first] == ranks[second] &&
		(serials[first] < serials[second] || serials[first] == serials[second] && first < second)
}

collect_roots :: proc "contextless" (node_count: int, ranks: [^]int, serials: [^]int,
		parents: [^]int, alive: [^]bool, roots: [^]int) -> int {
	count := 0
	for node := 0; node < node_count; node += 1 {
		if alive[node] && parents[node] == -1 { roots[count] = node; count += 1 }
	}
	for i := 1; i < count; i += 1 {
		key := roots[i]
		j := i
		for j > 0 && roots_before(key, roots[j-1], ranks, serials) {
			roots[j] = roots[j-1]
			j -= 1
		}
		roots[j] = key
	}
	return count
}

simple_link :: proc "contextless" (first, second: int, keys: [^]i64, serials: [^]int,
		items: [^]int, first_child: [^]int, next_sibling: [^]int,
		ranks: [^]int, parents: [^]int) -> int {
	winner := first
	loser := second
	if less_node(second, first, keys, serials, items) { winner = second; loser = first }
	next_sibling[loser] = first_child[winner]
	first_child[winner] = loser
	parents[loser] = winner
	ranks[winner] += 1
	return winner
}

skew_link :: proc "contextless" (singleton, first, second: int, keys: [^]i64,
		serials: [^]int, items: [^]int, first_child: [^]int,
		next_sibling: [^]int, ranks: [^]int, parents: [^]int) -> int {
	result_rank := ranks[first]+1
	winner := -1
	if less_node(singleton, first, keys, serials, items) && less_node(singleton, second, keys, serials, items) {
		winner = singleton
		first_child[winner] = first
		next_sibling[first] = second
		next_sibling[second] = -1
		parents[first] = winner
		parents[second] = winner
	} else {
		if less_node(first, second, keys, serials, items) { winner = first } else { winner = second }
		loser := second
		if winner == second { loser = first }
		old_children := first_child[winner]
		first_child[winner] = singleton
		next_sibling[singleton] = loser
		next_sibling[loser] = old_children
		parents[singleton] = winner
		parents[loser] = winner
	}
	parents[winner] = -1
	ranks[winner] = result_rank
	return winner
}

insert_singleton :: proc "contextless" (node, node_count: int, keys: [^]i64,
		serials: [^]int, items: [^]int, ranks: [^]int, parents: [^]int,
		alive: [^]bool, first_child: [^]int, next_sibling: [^]int) {
	parents[node] = -2
	roots: [MAX_OPERATIONS]int
	root_count := collect_roots(node_count, &ranks[0], &serials[0], &parents[0], &alive[0], &roots[0])
	if root_count >= 2 && ranks[roots[0]] == ranks[roots[1]] {
	_ = skew_link(node, roots[0], roots[1], keys, serials, items,
			first_child, next_sibling, ranks, parents)
	} else {
		parents[node] = -1
	}
}

normalize_equal_ranks :: proc "contextless" (input_roots: [^]int, root_count: int,
		keys: [^]i64, serials: [^]int, items: [^]int, first_child: [^]int,
		next_sibling: [^]int, ranks: [^]int, parents: [^]int) {
	ordered_roots: [MAX_OPERATIONS]int
	for i := 0; i < root_count; i += 1 { ordered_roots[i] = input_roots[i] }
	for i := 1; i < root_count; i += 1 {
		key := ordered_roots[i]
		j := i
		for j > 0 && roots_before(key, ordered_roots[j-1], ranks, serials) {
			ordered_roots[j] = ordered_roots[j-1]
			j -= 1
		}
		ordered_roots[j] = key
	}
	buckets: [MAX_RANK_BUCKETS]int
	for rank := 0; rank < MAX_RANK_BUCKETS; rank += 1 { buckets[rank] = -1 }
	for i := 0; i < root_count; i += 1 {
		current := ordered_roots[i]
		for {
			rank := ranks[current]
			if rank < 0 || rank >= MAX_RANK_BUCKETS do return
			if buckets[rank] < 0 { buckets[rank] = current; break }
			previous := buckets[rank]
			buckets[rank] = -1
			current = simple_link(previous, current, keys, serials, items,
				first_child, next_sibling, ranks, parents)
		}
	}
}

minimum_root :: proc "contextless" (node_count: int, keys: [^]i64,
		serials: [^]int, items: [^]int, parents: [^]int, alive: [^]bool) -> int {
	best := -1
	for node := 0; node < node_count; node += 1 {
		if alive[node] && parents[node] == -1 && (best < 0 || less_node(node, best, keys, serials, items)) {
			best = node
		}
	}
	return best
}

@(export)
skew_binomial_queue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	operation_count_value := input[0]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	if length != c.size_t(1+3*operation_count) do return -1

	keys: [MAX_OPERATIONS]i64
	serials: [MAX_OPERATIONS]int
	items: [MAX_OPERATIONS]int
	ranks: [MAX_OPERATIONS]int
	first_child: [MAX_OPERATIONS]int
	next_sibling: [MAX_OPERATIONS]int
	parents: [MAX_OPERATIONS]int
	alive: [MAX_OPERATIONS]bool
	item_nodes: [MAX_ITEMS]int
	active: [MAX_ITEMS]bool
	for node := 0; node < MAX_OPERATIONS; node += 1 {
		items[node] = -1
		first_child[node] = -1
		next_sibling[node] = -1
		parents[node] = -2
	}
	for item := 0; item < MAX_ITEMS; item += 1 { item_nodes[item] = -1 }

	node_count := 0
	insertion_serial := 0
	result: i64 = 0
	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		offset := 1+3*operation_index
		opcode := input[offset]
		item_value := input[offset+1]
		key := input[offset+2]
		if opcode == 1 {
			if item_value < 0 || item_value >= MAX_ITEMS || key < 0 || key > 1_000_000 do return -1
			item := int(item_value)
			if active[item] || node_count >= MAX_OPERATIONS do return -1
			node := node_count
			node_count += 1
			keys[node] = key
			serials[node] = insertion_serial
			insertion_serial += 1
			items[node] = item
			ranks[node] = 0
			first_child[node] = -1
			next_sibling[node] = -1
			parents[node] = -1
			alive[node] = true
			item_nodes[item] = node
			active[item] = true
			insert_singleton(node, node_count, &keys[0], &serials[0], &items[0], &ranks[0],
				&parents[0], &alive[0], &first_child[0], &next_sibling[0])
		} else if opcode == 2 || opcode == 3 {
			if item_value != 0 || key != 0 do return -1
			node := minimum_root(node_count, &keys[0], &serials[0], &items[0], &parents[0], &alive[0])
			if node < 0 do return -1
			item := items[node]
			result += i64(operation_index+1)*(keys[node]+1)+i64(item)
			if opcode == 2 do continue
			active[item] = false
			item_nodes[item] = -1
			children: [MAX_OPERATIONS]int
			child_count := 0
			child := first_child[node]
			for child >= 0 {
				following := next_sibling[child]
				parents[child] = -1
				next_sibling[child] = -1
				children[child_count] = child
				child_count += 1
				child = following
			}
			alive[node] = false
			parents[node] = -2
			items[node] = -1
			first_child[node] = -1
			next_sibling[node] = -1
			child_membership: [MAX_OPERATIONS]bool
			zero_children: [MAX_OPERATIONS]int
			zero_count := 0
			positive_children: [MAX_OPERATIONS]int
			positive_count := 0
			for i := 0; i < child_count; i += 1 {
				descendant := children[i]
				child_membership[descendant] = true
				if ranks[descendant] == 0 {
					zero_children[zero_count] = descendant
					zero_count += 1
				} else {
					positive_children[positive_count] = descendant
					positive_count += 1
				}
			}
			for i := 1; i < zero_count; i += 1 {
				value_node := zero_children[i]
				j := i
				for j > 0 && (serials[zero_children[j-1]] > serials[value_node] ||
					serials[zero_children[j-1]] == serials[value_node] && zero_children[j-1] > value_node) {
					zero_children[j] = zero_children[j-1]
					j -= 1
				}
				zero_children[j] = value_node
			}
			roots: [MAX_OPERATIONS]int
			root_count := 0
			for candidate := 0; candidate < node_count; candidate += 1 {
				if alive[candidate] && parents[candidate] == -1 && !child_membership[candidate] {
					roots[root_count] = candidate
					root_count += 1
				}
			}
			for i := 0; i < positive_count; i += 1 {
				roots[root_count] = positive_children[i]
				root_count += 1
			}
			normalize_equal_ranks(&roots[0], root_count, &keys[0], &serials[0], &items[0],
				&first_child[0], &next_sibling[0], &ranks[0], &parents[0])
			for i := 0; i < zero_count; i += 1 {
				insert_singleton(zero_children[i], node_count, &keys[0], &serials[0], &items[0], &ranks[0],
					&parents[0], &alive[0], &first_child[0], &next_sibling[0])
			}
		} else {
			return -1
		}
	}
	return result
}
