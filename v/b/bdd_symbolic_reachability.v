module bdd_symbolic_reachability

const max_input = 133
const max_nodes = 17000
const unique_cap = 32768
const unique_mask = unique_cap - 1

struct BddManager {
mut:
	variable       [max_nodes]u8
	low            [max_nodes]u16
	high           [max_nodes]u16
	unique         [unique_cap]u16
	next_id        int
	variable_count u8
	failed         bool
}

fn unique_hash(variable u8, low u16, high u16) int {
	return (int(variable) * 4099 + int(low) * 131 + int(high)) & unique_mask
}

fn make_node(mut manager BddManager, variable u8, low u16, high u16) u16 {
	if low == high { return low }
	mut slot := unique_hash(variable, low, high)
	for _ in 0 .. unique_cap {
		encoded := manager.unique[slot]
		if encoded == 0 {
			if manager.next_id >= max_nodes {
				manager.failed = true
				return 0
			}
			id := manager.next_id
			manager.variable[id] = variable
			manager.low[id] = low
			manager.high[id] = high
			manager.unique[slot] = u16(id + 1)
			manager.next_id++
			return u16(id)
		}
		id := int(encoded) - 1
		if manager.variable[id] == variable && manager.low[id] == low && manager.high[id] == high { return u16(id) }
		slot = (slot + 1) & unique_mask
	}
	manager.failed = true
	return 0
}

fn reset_round(mut manager BddManager, persistent_next int) {
	for slot in 0 .. unique_cap { manager.unique[slot] = 0 }
	manager.next_id = persistent_next
	for id in 2 .. persistent_next {
		mut slot := unique_hash(manager.variable[id], manager.low[id], manager.high[id])
		for manager.unique[slot] != 0 { slot = (slot + 1) & unique_mask }
		manager.unique[slot] = u16(id + 1)
	}
	manager.failed = false
}

fn top_variable(manager &BddManager, node u16) u8 {
	if node < 2 { return manager.variable_count }
	return manager.variable[node]
}

fn apply_recursive(mut manager BddManager, left u16, right u16, is_or bool) u16 {
	if manager.failed { return 0 }
	if is_or {
		if left == 1 || right == 1 { return 1 }
		if left == 0 { return right }
		if right == 0 || left == right { return left }
	} else {
		if left == 0 || right == 0 { return 0 }
		if left == 1 { return right }
		if right == 1 || left == right { return left }
	}
	mut variable := top_variable(manager, left)
	other_variable := top_variable(manager, right)
	if other_variable < variable { variable = other_variable }
	mut left_low := left
	mut left_high := left
	mut right_low := right
	mut right_high := right
	if left >= 2 && manager.variable[left] == variable {
		left_low = manager.low[left]
		left_high = manager.high[left]
	}
	if right >= 2 && manager.variable[right] == variable {
		right_low = manager.low[right]
		right_high = manager.high[right]
	}
	low := apply_recursive(mut manager, left_low, right_low, is_or)
	high := apply_recursive(mut manager, left_high, right_high, is_or)
	return make_node(mut manager, variable, low, high)
}

fn truth_table_recursive(mut manager BddManager, input &i64, offset int, variable u8, prefix int, variable_count u8) u16 {
	if manager.failed { return 0 }
	if variable == variable_count { return u16(unsafe { input[offset + prefix] }) }
	low := truth_table_recursive(mut manager, input, offset, variable + 1, prefix * 2, variable_count)
	high := truth_table_recursive(mut manager, input, offset, variable + 1, prefix * 2 + 1, variable_count)
	return make_node(mut manager, variable, low, high)
}

fn state_set_recursive(mut manager BddManager, mask u16, variable u8, prefix int, variable_count u8) u16 {
	if manager.failed { return 0 }
	if variable == variable_count { return (mask >> u8(prefix)) & 1 }
	low := state_set_recursive(mut manager, mask, variable + 1, prefix * 2, variable_count)
	high := state_set_recursive(mut manager, mask, variable + 1, prefix * 2 + 1, variable_count)
	return make_node(mut manager, variable, low, high)
}

fn exists_recursive(mut manager BddManager, node u16, quantified_variables u8) u16 {
	if manager.failed || node < 2 { return node }
	variable := manager.variable[node]
	low := exists_recursive(mut manager, manager.low[node], quantified_variables)
	high := exists_recursive(mut manager, manager.high[node], quantified_variables)
	if variable < quantified_variables { return apply_recursive(mut manager, low, high, true) }
	return make_node(mut manager, variable, low, high)
}

fn rename_recursive(mut manager BddManager, node u16, first_variable u8) u16 {
	if manager.failed || node < 2 { return node }
	variable := manager.variable[node]
	if variable < first_variable {
		manager.failed = true
		return 0
	}
	low := rename_recursive(mut manager, manager.low[node], first_variable)
	high := rename_recursive(mut manager, manager.high[node], first_variable)
	return make_node(mut manager, variable - first_variable, low, high)
}

fn evaluate(manager &BddManager, root u16, assignment u16, variable_count u8) u16 {
	mut node := root
	for node >= 2 {
		variable := manager.variable[node]
		shift := variable_count - variable - 1
		if ((assignment >> shift) & 1) != 0 { node = manager.high[node] } else { node = manager.low[node] }
	}
	return node
}

@[export: 'bdd_symbolic_reachability']
pub fn bdd_symbolic_reachability(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input { return -1 }
	unsafe {
		n_raw, m_raw, initial_raw, invariant_raw := input[0], input[1], input[2], input[3]
		if n_raw < 1 || n_raw > 3 || m_raw < 0 || m_raw > 1 { return -1 }
		n, m := int(n_raw), int(m_raw)
		state_count := 1 << n
		state_mask := (1 << state_count) - 1
		relation_length := 1 << (2 * n + m)
		if initial_raw < 0 || invariant_raw < 0 || (initial_raw >> state_count) != 0 || (invariant_raw >> state_count) != 0 || length != usize(4 + relation_length) { return -1 }
		for i in 0 .. relation_length {
			if input[4 + i] != 0 && input[4 + i] != 1 { return -1 }
		}
		mut manager := BddManager{
			next_id: 2
			variable_count: u8(2 * n + m)
		}
		relation := truth_table_recursive(mut manager, input, 4, 0, 0, manager.variable_count)
		if manager.failed { return -1 }
		persistent_next := manager.next_id
		mut reached_mask := u16(initial_raw & i64(state_mask))
		for iteration in 0 .. state_count + 1 {
			reset_round(mut manager, persistent_next)
			reached := state_set_recursive(mut manager, reached_mask, 0, 0, u8(n))
			product := apply_recursive(mut manager, reached, relation, false)
			next_set := exists_recursive(mut manager, product, u8(n + m))
			current_set := rename_recursive(mut manager, next_set, u8(n + m))
			joined := apply_recursive(mut manager, reached, current_set, true)
			if manager.failed { return -1 }
			if joined == reached { break }
			reached_mask = 0
			for state in 0 .. state_count {
				reached_mask |= evaluate(manager, joined, u16(state), u8(n)) << u8(state)
			}
			if iteration == state_count { return -1 }
		}
		violation := (reached_mask & ~u16(invariant_raw)) != 0
		return (i64(reached_mask) << 1) | i64(violation)
	}
}
