module rank_pairing_heap

const max_operations = 64
const max_items = 32
const max_nodes = 64
const max_input_length = 194

struct RankPairingState {
mut:
	keys [max_nodes]i64
	items [max_nodes]int
	ranks [max_nodes]int
	left [max_nodes]int
	right [max_nodes]int
	parents [max_nodes]int
	alive [max_nodes]bool
	item_nodes [max_items]int
	active [max_items]bool
	node_count int
}

fn rph_rank(ranks [max_nodes]int, node int) int {
	if node < 0 { return -1 }
	return ranks[node]
}

fn rph_minimum_root(state &RankPairingState) int {
	mut best := -1
	for node in 0 .. state.node_count {
		if !state.alive[node] || state.parents[node] != -1 { continue }
		if best < 0 || state.keys[node] < state.keys[best] || (state.keys[node] == state.keys[best] && (state.items[node] < state.items[best] || (state.items[node] == state.items[best] && node < best))) {
			best = node
		}
	}
	return best
}

fn rph_consolidate(mut state &RankPairingState) {
	for {
		mut duplicate_rank := -1
		for rank_value in 0 .. state.node_count {
			mut roots_at_rank := 0
			for node in 0 .. state.node_count {
				if state.alive[node] && state.parents[node] == -1 && state.ranks[node] == rank_value { roots_at_rank++ }
			}
			if roots_at_rank >= 2 { duplicate_rank = rank_value; break }
		}
		if duplicate_rank < 0 { return }
		mut first, second := -1, -1
		for node in 0 .. state.node_count {
			if state.alive[node] && state.parents[node] == -1 && state.ranks[node] == duplicate_rank {
				if first < 0 { first = node } else if second < 0 { second = node; break }
			}
		}
		mut winner, loser := first, second
		if state.keys[second] < state.keys[first] || (state.keys[second] == state.keys[first] && (state.items[second] < state.items[first] || (state.items[second] == state.items[first] && second < first))) {
			winner, loser = second, first
		}
		old_left := state.left[winner]
		state.left[winner] = loser
		state.parents[loser] = winner
		state.right[loser] = old_left
		if old_left >= 0 { state.parents[old_left] = loser }
		state.ranks[winner]++
	}
}

fn solve(operation_count int, input &i64) i64 {
	mut state := RankPairingState{}
	for index in 0 .. max_nodes {
		state.items[index] = -1
		state.left[index] = -1
		state.right[index] = -1
		state.parents[index] = -2
	}
	for item_id in 0 .. max_items { state.item_nodes[item_id] = -1 }
	mut result := i64(0)
	unsafe {
		for operation_index in 0 .. operation_count {
			offset := 1 + 3 * operation_index
			opcode, item_value, value := input[offset], input[offset + 1], input[offset + 2]
			if opcode == 1 {
				if item_value < 0 || item_value >= max_items || value < 0 || value > 1_000_000 { return -1 }
				item_id := int(item_value)
				if state.active[item_id] || state.node_count >= max_nodes { return -1 }
				node := state.node_count
				state.node_count++
				state.keys[node] = value
				state.items[node] = item_id
				state.ranks[node] = 0
				state.left[node] = -1
				state.right[node] = -1
				state.parents[node] = -1
				state.alive[node] = true
				state.item_nodes[item_id] = node
				state.active[item_id] = true
			} else if opcode == 2 {
				if item_value < 0 || item_value >= max_items || value < 0 || value > 1_000_000 { return -1 }
				item_id := int(item_value)
				if !state.active[item_id] || state.node_count >= max_nodes { return -1 }
				node := state.item_nodes[item_id]
				if value >= state.keys[node] { return -1 }
				state.keys[node] = value
				if state.parents[node] >= 0 {
					old_parent := state.parents[node]
					next_sibling := state.right[node]
					if state.left[old_parent] == node { state.left[old_parent] = next_sibling } else { state.right[old_parent] = next_sibling }
					if next_sibling >= 0 { state.parents[next_sibling] = old_parent }
					state.parents[node] = -1
					state.right[node] = -1
					state.ranks[node] = rph_rank(state.ranks, state.left[node]) + 1
					ancestor := old_parent
					for ancestor >= 0 {
						if state.parents[ancestor] < 0 {
							state.ranks[ancestor] = rph_rank(state.ranks, state.left[ancestor]) + 1
							break
						}
						left_rank := rph_rank(state.ranks, state.left[ancestor])
						right_rank := rph_rank(state.ranks, state.right[ancestor])
						mut new_rank := left_rank + 1
						if left_rank != right_rank { new_rank = max(left_rank, right_rank) }
						if new_rank >= state.ranks[ancestor] { break }
						state.ranks[ancestor] = new_rank
						ancestor = state.parents[ancestor]
					}
				}
			} else if opcode == 3 {
				if item_value != 0 || value != 0 { return -1 }
				root := rph_minimum_root(state)
				if root < 0 { return -1 }
				removed_item := state.items[root]
				result += i64(operation_index + 1) * (state.keys[root] + 1) + i64(removed_item)
				state.active[removed_item] = false
				state.item_nodes[removed_item] = -1
				mut child := state.left[root]
				for child >= 0 {
					next_sibling := state.right[child]
					state.right[child] = -1
					state.parents[child] = -1
					state.ranks[child] = rph_rank(state.ranks, state.left[child]) + 1
					child = next_sibling
				}
				state.alive[root] = false
				state.parents[root] = -2
				state.left[root] = -1
				state.right[root] = -1
				state.items[root] = -1
				rph_consolidate(mut state)
			} else if opcode == 4 {
				if item_value != 0 || value != 0 { return -1 }
				root := rph_minimum_root(state)
				if root < 0 { return -1 }
				result += i64(operation_index + 1) * (state.keys[root] + 1) + i64(state.items[root])
			} else { return -1 }
		}
	}
	return result
}

@[export: 'rank_pairing_heap']
pub fn rank_pairing_heap(input &i64, length usize) i64 {
	if input == nil || length < 1 || length > max_input_length { return -1 }
	unsafe {
		operation_value := input[0]
		if operation_value < 0 || operation_value > max_operations { return -1 }
		operation_count := int(operation_value)
		if length != usize(1 + 3 * operation_count) || length > 193 { return -1 }
		return solve(operation_count, input)
	}
}
