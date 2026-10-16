const invalid_result = -1e300

fn integer_power(value f64, exponent int) f64 {
	mut result := 1.0
	for _ in 0 .. exponent { result *= value }
	return result
}

@[export: 'automatic_differentiation']
pub fn automatic_differentiation(input &i64, length usize) f64 {
	if length < 8 || isnil(input) { return invalid_result }
	leaves_value := unsafe { input[0] }
	operations_value := unsafe { input[1] }
	if leaves_value < 1 || leaves_value > 32 || operations_value < 1 || operations_value > 64 {
		return invalid_result
	}
	leaves := int(leaves_value)
	operation_count := int(operations_value)
	if length != usize(4 + leaves + 3 * operation_count) { return invalid_result }
	node_count := leaves + operation_count
	target_value := unsafe { input[2] }
	source_value := unsafe { input[3] }
	if target_value < leaves_value || target_value >= i64(node_count) || source_value < 0 || source_value >= leaves_value {
		return invalid_result
	}
	target := int(target_value)
	source := int(source_value)

	mut nodes := []f64{len: 96, init: 0}
	mut opcodes := []i64{len: 64, init: 0}
	mut left_nodes := []int{len: 64, init: 0}
	mut right_fields := []i64{len: 64, init: 0}
	for index in 0 .. leaves {
		value := unsafe { input[4 + index] }
		if value < -16 || value > 16 { return invalid_result }
		nodes[index] = f64(value)
	}
	mut offset := 4 + leaves
	for operation in 0 .. operation_count {
		opcode := unsafe { input[offset] }
		left_value := unsafe { input[offset + 1] }
		right_value := unsafe { input[offset + 2] }
		output_node := leaves + operation
		if left_value < 0 || left_value >= i64(output_node) { return invalid_result }
		left := int(left_value)
		mut result := f64(0)
		if opcode == 5 {
			if right_value < 1 || right_value > 8 { return invalid_result }
			result = integer_power(nodes[left], int(right_value))
		} else {
			if opcode < 0 || opcode > 3 || right_value < 0 || right_value >= i64(output_node) { return invalid_result }
			right := int(right_value)
			if opcode == 0 { result = nodes[left] + nodes[right] }
			else if opcode == 1 { result = nodes[left] - nodes[right] }
			else if opcode == 2 { result = nodes[left] * nodes[right] }
			else {
				if nodes[right] == 0 { return invalid_result }
				result = nodes[left] / nodes[right]
			}
		}
		if result != result || result < -10_000_000_000.0 || result > 10_000_000_000.0 { return invalid_result }
		nodes[output_node] = result
		opcodes[operation] = opcode
		left_nodes[operation] = left
		right_fields[operation] = right_value
		offset += 3
	}

	mut adjoints := []f64{len: 96, init: 0}
	mut ancestors := []bool{len: 96, init: false}
	adjoints[target] = 1
	ancestors[target] = true
	mut cursor := target - leaves + 1
	for cursor > 0 {
		cursor--
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
			right := int(right_fields[cursor]); left_value := nodes[left]; right_value := nodes[right]
			ancestors[right] = true
			adjoints[left] += (1.0 / right_value) * adjoint
			adjoints[right] += (-left_value / (right_value * right_value)) * adjoint
		} else {
			exponent := int(right_fields[cursor])
			local_derivative := f64(exponent) * integer_power(nodes[left], exponent - 1)
			adjoints[left] += local_derivative * adjoint
		}
	}
	if !ancestors[source] || adjoints[source] != adjoints[source] || adjoints[source] < -1e300 || adjoints[source] > 1e300 {
		return invalid_result
	}
	return adjoints[source]
}
