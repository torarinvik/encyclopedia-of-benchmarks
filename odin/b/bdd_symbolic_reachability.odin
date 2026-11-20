package bdd_symbolic_reachability

import "core:c"

MAX_INPUT :: 133
MAX_NODES :: 17000
UNIQUE_CAP :: 32768
UNIQUE_MASK :: UNIQUE_CAP - 1

Bdd_Manager :: struct {
	variable: [MAX_NODES]u8,
	low: [MAX_NODES]u16,
	high: [MAX_NODES]u16,
	unique: [UNIQUE_CAP]u16,
	next_id: int,
	variable_count: u8,
	failed: bool,
}

unique_hash :: proc(variable: u8, low, high: u16) -> int {
	return (int(variable) * 4099 + int(low) * 131 + int(high)) & UNIQUE_MASK
}

make_node :: proc(manager: ^Bdd_Manager, variable: u8, low, high: u16) -> u16 {
	if low == high do return low
	slot := unique_hash(variable, low, high)
	for probe := 0; probe < UNIQUE_CAP; probe += 1 {
		encoded := manager.unique[slot]
		if encoded == 0 {
			if manager.next_id >= MAX_NODES {
				manager.failed = true
				return 0
			}
			id := manager.next_id
			manager.variable[id] = variable
			manager.low[id] = low
			manager.high[id] = high
			manager.unique[slot] = u16(id + 1)
			manager.next_id += 1
			return u16(id)
		}
		id := int(encoded) - 1
		if manager.variable[id] == variable && manager.low[id] == low && manager.high[id] == high do return u16(id)
		slot = (slot + 1) & UNIQUE_MASK
	}
	manager.failed = true
	return 0
}

reset_round :: proc(manager: ^Bdd_Manager, persistent_next: int) {
	for slot := 0; slot < UNIQUE_CAP; slot += 1 do manager.unique[slot] = 0
	manager.next_id = persistent_next
	for id := 2; id < persistent_next; id += 1 {
		slot := unique_hash(manager.variable[id], manager.low[id], manager.high[id])
		for manager.unique[slot] != 0 do slot = (slot + 1) & UNIQUE_MASK
		manager.unique[slot] = u16(id + 1)
	}
	manager.failed = false
}

top_variable :: proc(manager: ^Bdd_Manager, node: u16) -> u8 {
	if node < 2 do return manager.variable_count
	return manager.variable[node]
}

children_at :: proc(manager: ^Bdd_Manager, node: u16, variable: u8, low, high: ^u16) {
	if node >= 2 && manager.variable[node] == variable {
		low^ = manager.low[node]
		high^ = manager.high[node]
	} else {
		low^ = node
		high^ = node
	}
}

apply_recursive :: proc(manager: ^Bdd_Manager, left, right: u16, is_or: bool) -> u16 {
	if manager.failed do return 0
	if is_or {
		if left == 1 || right == 1 do return 1
		if left == 0 do return right
		if right == 0 || left == right do return left
	} else {
		if left == 0 || right == 0 do return 0
		if left == 1 do return right
		if right == 1 || left == right do return left
	}
	variable := top_variable(manager, left)
	other_variable := top_variable(manager, right)
	if other_variable < variable do variable = other_variable
	left_low, left_high, right_low, right_high: u16
	children_at(manager, left, variable, &left_low, &left_high)
	children_at(manager, right, variable, &right_low, &right_high)
	low := apply_recursive(manager, left_low, right_low, is_or)
	high := apply_recursive(manager, left_high, right_high, is_or)
	return make_node(manager, variable, low, high)
}

truth_table_recursive :: proc(manager: ^Bdd_Manager, bits: [^]i64, offset: int, variable: u8, prefix: int, variable_count: u8) -> u16 {
	if manager.failed do return 0
	if variable == variable_count do return u16(bits[offset + prefix])
	low := truth_table_recursive(manager, bits, offset, variable + 1, prefix * 2, variable_count)
	high := truth_table_recursive(manager, bits, offset, variable + 1, prefix * 2 + 1, variable_count)
	return make_node(manager, variable, low, high)
}

state_set_recursive :: proc(manager: ^Bdd_Manager, mask: u16, variable: u8, prefix: int, variable_count: u8) -> u16 {
	if manager.failed do return 0
	if variable == variable_count do return u16((mask >> u8(prefix)) & 1)
	low := state_set_recursive(manager, mask, variable + 1, prefix * 2, variable_count)
	high := state_set_recursive(manager, mask, variable + 1, prefix * 2 + 1, variable_count)
	return make_node(manager, variable, low, high)
}

exists_recursive :: proc(manager: ^Bdd_Manager, node: u16, quantified_variables: u8) -> u16 {
	if manager.failed || node < 2 do return node
	variable := manager.variable[node]
	low := exists_recursive(manager, manager.low[node], quantified_variables)
	high := exists_recursive(manager, manager.high[node], quantified_variables)
	if variable < quantified_variables do return apply_recursive(manager, low, high, true)
	return make_node(manager, variable, low, high)
}

rename_recursive :: proc(manager: ^Bdd_Manager, node: u16, first_variable: u8) -> u16 {
	if manager.failed || node < 2 do return node
	variable := manager.variable[node]
	if variable < first_variable {
		manager.failed = true
		return 0
	}
	low := rename_recursive(manager, manager.low[node], first_variable)
	high := rename_recursive(manager, manager.high[node], first_variable)
	return make_node(manager, variable - first_variable, low, high)
}

evaluate :: proc(manager: ^Bdd_Manager, root, assignment: u16, variable_count: u8) -> u16 {
	node := root
	for node >= 2 {
		variable := manager.variable[node]
		shift := variable_count - variable - 1
		if ((assignment >> shift) & 1) != 0 do node = manager.high[node] else do node = manager.low[node]
	}
	return node
}

@(export)
bdd_symbolic_reachability :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n_raw, m_raw, initial_raw, invariant_raw := input[0], input[1], input[2], input[3]
	if n_raw < 1 || n_raw > 3 || m_raw < 0 || m_raw > 1 do return -1
	n, m := int(n_raw), int(m_raw)
	state_count := 1 << n
	state_mask := (1 << state_count) - 1
	relation_length := 1 << (2*n + m)
	if initial_raw < 0 || invariant_raw < 0 || (initial_raw >> state_count) != 0 || (invariant_raw >> state_count) != 0 || length != c.size_t(4 + relation_length) do return -1
	for i := 0; i < relation_length; i += 1 do if input[4+i] != 0 && input[4+i] != 1 do return -1

	manager := Bdd_Manager{}
	manager.next_id = 2
	manager.variable_count = u8(2*n + m)
	relation := truth_table_recursive(&manager, input, 4, 0, 0, manager.variable_count)
	if manager.failed do return -1
	persistent_next := manager.next_id
	reached_mask := u16(initial_raw)
	for iteration := 0; iteration <= state_count; iteration += 1 {
		reset_round(&manager, persistent_next)
		reached := state_set_recursive(&manager, reached_mask, 0, 0, u8(n))
		product := apply_recursive(&manager, reached, relation, false)
		next_set := exists_recursive(&manager, product, u8(n + m))
		current_set := rename_recursive(&manager, next_set, u8(n + m))
		joined := apply_recursive(&manager, reached, current_set, true)
		if manager.failed do return -1
		if joined == reached do break
		reached_mask = 0
		for state := 0; state < state_count; state += 1 do reached_mask |= evaluate(&manager, joined, u16(state), u8(n)) << u8(state)
		if iteration == state_count do return -1
	}
	violation := (reached_mask & ~u16(invariant_raw)) != 0
	return (i64(reached_mask) << 1) | i64(violation)
}
