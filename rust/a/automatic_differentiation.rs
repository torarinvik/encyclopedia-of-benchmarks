/* Scalar reverse-mode port of TheAlgorithms/Python automatic_differentiation.py. */
const MAX_LEAVES: usize = 32;
const MAX_OPERATIONS: usize = 64;
const MAX_NODES: usize = MAX_LEAVES + MAX_OPERATIONS;
const INVALID_RESULT: f64 = -1e300;

fn integer_power(value: f64, exponent: usize) -> f64 {
    let mut result = 1.0;
    for _ in 0..exponent { result *= value; }
    result
}

#[no_mangle]
pub unsafe extern "C" fn automatic_differentiation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 8 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let leaves_value = values[0];
    let operations_value = values[1];
    if !(1..=MAX_LEAVES as i64).contains(&leaves_value)
        || !(1..=MAX_OPERATIONS as i64).contains(&operations_value) { return INVALID_RESULT; }
    let leaves = leaves_value as usize;
    let operation_count = operations_value as usize;
    if length != 4 + leaves + 3 * operation_count { return INVALID_RESULT; }
    let target_value = values[2];
    let source_value = values[3];
    let node_count = leaves + operation_count;
    if target_value < leaves_value || target_value >= node_count as i64
        || source_value < 0 || source_value >= leaves_value { return INVALID_RESULT; }
    let target = target_value as usize;
    let source = source_value as usize;

    let mut nodes = [0.0f64; MAX_NODES];
    let mut opcodes = [0i64; MAX_OPERATIONS];
    let mut left_nodes = [0usize; MAX_OPERATIONS];
    let mut right_fields = [0i64; MAX_OPERATIONS];
    for index in 0..leaves {
        let value = values[4 + index];
        if !(-16..=16).contains(&value) { return INVALID_RESULT; }
        nodes[index] = value as f64;
    }

    let mut offset = 4 + leaves;
    for operation in 0..operation_count {
        let opcode = values[offset];
        let left_value = values[offset + 1];
        let right_value = values[offset + 2];
        let output_node = leaves + operation;
        if left_value < 0 || left_value >= output_node as i64 { return INVALID_RESULT; }
        let left = left_value as usize;
        let result;
        if opcode == 5 {
            if !(1..=8).contains(&right_value) { return INVALID_RESULT; }
            result = integer_power(nodes[left], right_value as usize);
        } else {
            if !(0..=3).contains(&opcode) || right_value < 0 || right_value >= output_node as i64 {
                return INVALID_RESULT;
            }
            let right = right_value as usize;
            let right_operand = nodes[right];
            result = match opcode {
                0 => nodes[left] + right_operand,
                1 => nodes[left] - right_operand,
                2 => nodes[left] * right_operand,
                _ if right_operand != 0.0 => nodes[left] / right_operand,
                _ => return INVALID_RESULT,
            };
        }
        if !result.is_finite() || result.abs() > 10_000_000_000.0 { return INVALID_RESULT; }
        nodes[output_node] = result;
        opcodes[operation] = opcode;
        left_nodes[operation] = left;
        right_fields[operation] = right_value;
        offset += 3;
    }

    let mut adjoints = [0.0f64; MAX_NODES];
    let mut ancestors = [false; MAX_NODES];
    adjoints[target] = 1.0;
    ancestors[target] = true;
    for cursor in (0..=(target - leaves)).rev() {
        let output_node = leaves + cursor;
        if !ancestors[output_node] { continue; }
        let left = left_nodes[cursor];
        let adjoint = adjoints[output_node];
        ancestors[left] = true;
        match opcodes[cursor] {
            0 => {
                let right = right_fields[cursor] as usize;
                ancestors[right] = true;
                adjoints[left] += adjoint;
                adjoints[right] += adjoint;
            }
            1 => {
                let right = right_fields[cursor] as usize;
                ancestors[right] = true;
                adjoints[left] += adjoint;
                adjoints[right] -= adjoint;
            }
            2 => {
                let right = right_fields[cursor] as usize;
                ancestors[right] = true;
                adjoints[left] += nodes[right] * adjoint;
                adjoints[right] += nodes[left] * adjoint;
            }
            3 => {
                let right = right_fields[cursor] as usize;
                let left_value = nodes[left];
                let right_value = nodes[right];
                ancestors[right] = true;
                adjoints[left] += (1.0 / right_value) * adjoint;
                adjoints[right] += (-left_value / (right_value * right_value)) * adjoint;
            }
            5 => {
                let exponent = right_fields[cursor] as usize;
                let local_derivative = exponent as f64 * integer_power(nodes[left], exponent - 1);
                adjoints[left] += local_derivative * adjoint;
            }
            _ => return INVALID_RESULT,
        }
    }
    let result = adjoints[source];
    if !ancestors[source] || !result.is_finite() || result.abs() > 1e300 {
        INVALID_RESULT
    } else {
        result
    }
}
