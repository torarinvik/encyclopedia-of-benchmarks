const invalid_result: f64 = -1.0e300;

fn integerPower(value: f64, exponent: usize) f64 {
    var result: f64 = 1.0;
    for (0..exponent) |_| result *= value;
    return result;
}

pub export fn automatic_differentiation(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 8) return invalid_result;
    const leaves_value = input[0];
    const operations_value = input[1];
    if (leaves_value < 1 or leaves_value > 32 or operations_value < 1 or operations_value > 64)
        return invalid_result;
    const leaves: usize = @intCast(leaves_value);
    const operation_count: usize = @intCast(operations_value);
    if (length != 4 + leaves + 3 * operation_count) return invalid_result;
    const node_count = leaves + operation_count;
    const target_value = input[2];
    const source_value = input[3];
    if (target_value < leaves_value or target_value >= @as(i64, @intCast(node_count)) or
        source_value < 0 or source_value >= leaves_value) return invalid_result;
    const target: usize = @intCast(target_value);
    const source: usize = @intCast(source_value);

    var nodes: [96]f64 = @splat(0.0);
    var opcodes: [64]i64 = @splat(0);
    var left_nodes: [64]usize = @splat(0);
    var right_fields: [64]i64 = @splat(0);
    for (0..leaves) |index| {
        const value = input[4 + index];
        if (value < -16 or value > 16) return invalid_result;
        nodes[index] = @floatFromInt(value);
    }
    var offset: usize = 4 + leaves;
    for (0..operation_count) |operation| {
        const opcode = input[offset];
        const left_value = input[offset + 1];
        const right_value = input[offset + 2];
        const output_node = leaves + operation;
        if (left_value < 0 or left_value >= @as(i64, @intCast(output_node))) return invalid_result;
        const left: usize = @intCast(left_value);
        var result: f64 = 0.0;
        if (opcode == 5) {
            if (right_value < 1 or right_value > 8) return invalid_result;
            result = integerPower(nodes[left], @intCast(right_value));
        } else {
            if (opcode < 0 or opcode > 3 or right_value < 0 or
                right_value >= @as(i64, @intCast(output_node))) return invalid_result;
            const right: usize = @intCast(right_value);
            if (opcode == 0) result = nodes[left] + nodes[right] else if (opcode == 1)
                result = nodes[left] - nodes[right] else if (opcode == 2)
                result = nodes[left] * nodes[right] else {
                if (nodes[right] == 0.0) return invalid_result;
                result = nodes[left] / nodes[right];
            }
        }
        if (result != result or result < -10_000_000_000.0 or result > 10_000_000_000.0)
            return invalid_result;
        nodes[output_node] = result;
        opcodes[operation] = opcode;
        left_nodes[operation] = left;
        right_fields[operation] = right_value;
        offset += 3;
    }

    var adjoints: [96]f64 = @splat(0.0);
    var ancestors: [96]bool = @splat(false);
    adjoints[target] = 1.0;
    ancestors[target] = true;
    var cursor = target - leaves + 1;
    while (cursor > 0) {
        cursor -= 1;
        const output_node = leaves + cursor;
        if (!ancestors[output_node]) continue;
        const left = left_nodes[cursor];
        const adjoint = adjoints[output_node];
        ancestors[left] = true;
        const opcode = opcodes[cursor];
        if (opcode == 0) {
            const right: usize = @intCast(right_fields[cursor]);
            ancestors[right] = true;
            adjoints[left] += adjoint;
            adjoints[right] += adjoint;
        } else if (opcode == 1) {
            const right: usize = @intCast(right_fields[cursor]);
            ancestors[right] = true;
            adjoints[left] += adjoint;
            adjoints[right] -= adjoint;
        } else if (opcode == 2) {
            const right: usize = @intCast(right_fields[cursor]);
            ancestors[right] = true;
            adjoints[left] += nodes[right] * adjoint;
            adjoints[right] += nodes[left] * adjoint;
        } else if (opcode == 3) {
            const right: usize = @intCast(right_fields[cursor]);
            const left_value = nodes[left];
            const right_value = nodes[right];
            ancestors[right] = true;
            adjoints[left] += (1.0 / right_value) * adjoint;
            adjoints[right] += (-left_value / (right_value * right_value)) * adjoint;
        } else {
            const exponent: usize = @intCast(right_fields[cursor]);
            const local_derivative = @as(f64, @floatFromInt(exponent)) *
                integerPower(nodes[left], exponent - 1);
            adjoints[left] += local_derivative * adjoint;
        }
    }
    const result = adjoints[source];
    if (!ancestors[source] or result != result or result < -1.0e300 or result > 1.0e300)
        return invalid_result;
    return result;
}
