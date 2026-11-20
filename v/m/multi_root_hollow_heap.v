module multi_root_hollow_heap

const max_operations = 64
const max_items = 32
const max_nodes = 64
const max_input_length = 194

struct MultiRootHollowState {
mut:
	keys [max_nodes]i64
	items [max_nodes]int
	ranks [max_nodes]int
	parents [max_nodes]int
	alive [max_nodes]bool
	item_nodes [max_items]int
	active [max_items]bool
	node_count int
}

fn mrhh_minimum_root(state &MultiRootHollowState) int {
	mut best := -1
	for node in 0 .. state.node_count {
		if !state.alive[node] || state.parents[node] != -1 || state.items[node] < 0 { continue }
		if best < 0 || state.keys[node] < state.keys[best] || (state.keys[node] == state.keys[best] && (state.items[node] < state.items[best] || (state.items[node] == state.items[best] && node < best))) {
			best = node
		}
	}
	return best
}

fn mrhh_cleanup(mut state &MultiRootHollowState) {
	for {
		mut hollow_root := -1
		for node in 0 .. state.node_count {
			if state.alive[node] && state.parents[node] == -1 && state.items[node] == -1 {
				hollow_root = node
				break
			}
		}
		if hollow_root < 0 { break }
		for child in 0 .. state.node_count {
			if state.alive[child] && state.parents[child] == hollow_root { state.parents[child] = -1 }
		}
		state.alive[hollow_root] = false
		state.parents[hollow_root] = -2
	}

	for {
		mut duplicate_rank := -1
		for rank_value in 0 .. state.node_count {
			mut roots_at_rank := 0
			for node in 0 .. state.node_count {
				if state.alive[node] && state.parents[node] == -1 && state.items[node] >= 0 && state.ranks[node] == rank_value { roots_at_rank++ }
			}
			if roots_at_rank >= 2 { duplicate_rank = rank_value; break }
		}
		if duplicate_rank < 0 { return }
		mut first, second := -1, -1
		for node in 0 .. state.node_count {
			if state.alive[node] && state.parents[node] == -1 && state.items[node] >= 0 && state.ranks[node] == duplicate_rank {
				if first < 0 { first = node } else if second < 0 { second = node; break }
			}
		}
		mut winner, loser := first, second
		if state.keys[second] < state.keys[first] || (state.keys[second] == state.keys[first] && (state.items[second] < state.items[first] || (state.items[second] == state.items[first] && second < first))) {
			winner, loser = second, first
		}
		state.parents[loser] = winner
		state.ranks[winner]++
	}
}

fn solve(operation_count int, input &i64) i64 {
	mut state := MultiRootHollowState{}
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
				state.parents[node] = -1
				state.alive[node] = true
				state.item_nodes[item_id] = node
				state.active[item_id] = true
			} else if opcode == 2 {
				if item_value < 0 || item_value >= max_items || value < 0 || value > 1_000_000 { return -1 }
				item_id := int(item_value)
				if !state.active[item_id] || state.node_count >= max_nodes { return -1 }
				old_node := state.item_nodes[item_id]
				if value >= state.keys[old_node] { return -1 }
				old_rank := state.ranks[old_node]
				new_rank := if old_rank > 2 { old_rank - 2 } else { 0 }
				new_node := state.node_count
				state.node_count++
				state.items[old_node] = -1
				state.keys[new_node] = value
				state.items[new_node] = item_id
				state.ranks[new_node] = new_rank
				state.parents[new_node] = -1
				state.alive[new_node] = true
				for child in 0 .. new_node {
					if state.alive[child] && state.parents[child] == old_node && state.ranks[child] < new_rank { state.parents[child] = new_node }
				}
				state.item_nodes[item_id] = new_node
			} else if opcode == 3 {
				if item_value != 0 || value != 0 { return -1 }
				root := mrhh_minimum_root(state)
				if root < 0 { return -1 }
				item_id := state.items[root]
				state.active[item_id] = false
				state.item_nodes[item_id] = -1
				state.items[root] = -1
				result += i64(operation_index + 1) * (state.keys[root] + 1) + i64(item_id)
				mrhh_cleanup(mut state)
			} else if opcode == 4 {
				if item_value != 0 || value != 0 { return -1 }
				root := mrhh_minimum_root(state)
				if root < 0 { return -1 }
				result += i64(operation_index + 1) * (state.keys[root] + 1) + i64(state.items[root])
			} else if opcode == 5 {
				if item_value < 0 || item_value >= max_items || value != 0 { return -1 }
				item_id := int(item_value)
				if !state.active[item_id] { return -1 }
				node := state.item_nodes[item_id]
				was_minimum := node == mrhh_minimum_root(state)
				state.active[item_id] = false
				state.item_nodes[item_id] = -1
				state.items[node] = -1
				if was_minimum { mrhh_cleanup(mut state) }
			} else { return -1 }
		}
	}
	return result
}

@[export: 'multi_root_hollow_heap']
pub fn multi_root_hollow_heap(input &i64, length usize) i64 {
	if input == nil || length < 1 || length > max_input_length { return -1 }
	unsafe {
		operation_value := input[0]
		if operation_value < 0 || operation_value > max_operations { return -1 }
		operation_count := int(operation_value)
		if length != usize(1 + 3 * operation_count) || length > 193 { return -1 }
		return solve(operation_count, input)
	}
}
