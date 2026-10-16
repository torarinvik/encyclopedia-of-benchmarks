package automatic_differentiation

import "core:c"

MAX_LEAVES :: 32
MAX_OPERATIONS :: 64
MAX_NODES :: 96
INVALID_RESULT :: -1.0e300

integer_power :: proc "contextless" (value: f64, exponent: int) -> f64 {
	result := 1.0
	for index := 0; index < exponent; index += 1 { result *= value }
	return result
}

@(export)
automatic_differentiation :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 8 { return INVALID_RESULT }
	leaves_value, operations_value := input[0], input[1]
	if leaves_value < 1 || leaves_value > MAX_LEAVES || operations_value < 1 || operations_value > MAX_OPERATIONS {
		return INVALID_RESULT
	}
	leaves, operation_count := int(leaves_value), int(operations_value)
	if length != c.size_t(4 + leaves + 3 * operation_count) { return INVALID_RESULT }
	node_count := leaves + operation_count
	target_value, source_value := input[2], input[3]
	if target_value < leaves_value || target_value >= i64(node_count) || source_value < 0 || source_value >= leaves_value {
		return INVALID_RESULT
	}
	target, source := int(target_value), int(source_value)

	nodes: [MAX_NODES]f64
	opcodes: [MAX_OPERATIONS]i64
	left_nodes: [MAX_OPERATIONS]int
	right_fields: [MAX_OPERATIONS]i64
	for index := 0; index < leaves; index += 1 {
		value := input[4 + index]
		if value < -16 || value > 16 { return INVALID_RESULT }
		nodes[index] = f64(value)
	}
	offset := 4 + leaves
	for operation := 0; operation < operation_count; operation += 1 {
		opcode, left_value, right_value := input[offset], input[offset + 1], input[offset + 2]
		output_node := leaves + operation
		if left_value < 0 || left_value >= i64(output_node) { return INVALID_RESULT }
		left := int(left_value)
		result: f64 = 0
		if opcode == 5 {
			if right_value < 1 || right_value > 8 { return INVALID_RESULT }
			result = integer_power(nodes[left], int(right_value))
		} else {
			if opcode < 0 || opcode > 3 || right_value < 0 || right_value >= i64(output_node) { return INVALID_RESULT }
			right := int(right_value)
			if opcode == 0 { result = nodes[left] + nodes[right] }
			else if opcode == 1 { result = nodes[left] - nodes[right] }
			else if opcode == 2 { result = nodes[left] * nodes[right] }
			else {
				if nodes[right] == 0 { return INVALID_RESULT }
				result = nodes[left] / nodes[right]
			}
		}
		if result != result || result < -10_000_000_000.0 || result > 10_000_000_000.0 { return INVALID_RESULT }
		nodes[output_node] = result
		opcodes[operation], left_nodes[operation], right_fields[operation] = opcode, left, right_value
		offset += 3
	}

	adjoints: [MAX_NODES]f64
	ancestors: [MAX_NODES]bool
	adjoints[target] = 1
	ancestors[target] = true
	for cursor := target - leaves; cursor >= 0; cursor -= 1 {
		output_node := leaves + cursor
		if !ancestors[output_node] { continue }
		left := left_nodes[cursor]
		adjoint := adjoints[output_node]
		ancestors[left] = true
		opcode := opcodes[cursor]
		if opcode == 0 {
			right := int(right_fields[cursor]); ancestors[right] = true
			adjoints[left] += adjoint; adjoints[right] += adjoint
		} else if opcode == 1 {
			right := int(right_fields[cursor]); ancestors[right] = true
			adjoints[left] += adjoint; adjoints[right] -= adjoint
		} else if opcode == 2 {
			right := int(right_fields[cursor]); ancestors[right] = true
			adjoints[left] += nodes[right] * adjoint; adjoints[right] += nodes[left] * adjoint
		} else if opcode == 3 {
			right := int(right_fields[cursor]); left_value, right_value := nodes[left], nodes[right]
			ancestors[right] = true
			adjoints[left] += (1 / right_value) * adjoint
			adjoints[right] += (-left_value / (right_value * right_value)) * adjoint
		} else {
			exponent := int(right_fields[cursor])
			local_derivative := f64(exponent) * integer_power(nodes[left], exponent - 1)
			adjoints[left] += local_derivative * adjoint
		}
	}
	if !ancestors[source] || adjoints[source] != adjoints[source] || adjoints[source] < -1.0e300 || adjoints[source] > 1.0e300 {
		return INVALID_RESULT
	}
	return adjoints[source]
}
