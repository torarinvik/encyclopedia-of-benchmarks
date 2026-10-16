module automatic_differentiation;

const usz MAX_LEAVES = 32;
const usz MAX_OPERATIONS = 64;
const usz MAX_NODES = 96;
const double INVALID_RESULT = -1.0e300;

fn double integer_power(double value, usz exponent) {
    double result = 1.0;
    for (usz index = 0; index < exponent; index++) result *= value;
    return result;
}

fn double automatic_differentiation_impl(long* input, usz length) {
    if (input == null || length < 8) return INVALID_RESULT;
    long leaves_value = input[0];
    long operations_value = input[1];
    if (leaves_value < 1 || leaves_value > (long)MAX_LEAVES ||
        operations_value < 1 || operations_value > (long)MAX_OPERATIONS ||
        length != 4 + (usz)leaves_value + 3 * (usz)operations_value) return INVALID_RESULT;
    usz leaves = (usz)leaves_value;
    usz operation_count = (usz)operations_value;
    usz node_count = leaves + operation_count;
    long target_value = input[2];
    long source_value = input[3];
    if (target_value < leaves_value || target_value >= (long)node_count ||
        source_value < 0 || source_value >= leaves_value) return INVALID_RESULT;
    usz target = (usz)target_value;
    usz source = (usz)source_value;

    double[MAX_NODES] nodes;
    long[MAX_OPERATIONS] opcodes;
    usz[MAX_OPERATIONS] left_nodes;
    long[MAX_OPERATIONS] right_fields;
    for (usz index = 0; index < leaves; index++) {
        long value = input[4 + index];
        if (value < -16 || value > 16) return INVALID_RESULT;
        nodes[index] = (double)value;
    }
    usz offset = 4 + leaves;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[offset];
        long left_value = input[offset + 1];
        long right_value = input[offset + 2];
        usz output_node = leaves + operation;
        if (left_value < 0 || left_value >= (long)output_node) return INVALID_RESULT;
        usz left = (usz)left_value;
        double result;
        if (opcode == 5) {
            if (right_value < 1 || right_value > 8) return INVALID_RESULT;
            result = integer_power(nodes[left], (usz)right_value);
        } else {
            if (opcode < 0 || opcode > 3 || right_value < 0 || right_value >= (long)output_node) {
                return INVALID_RESULT;
            }
            double right = nodes[(usz)right_value];
            if (opcode == 0) { result = nodes[left] + right; }
            else if (opcode == 1) { result = nodes[left] - right; }
            else if (opcode == 2) { result = nodes[left] * right; }
            else {
                if (right == 0.0) return INVALID_RESULT;
                result = nodes[left] / right;
            }
        }
        if (result != result || result < -10000000000.0 || result > 10000000000.0) {
            return INVALID_RESULT;
        }
        nodes[output_node] = result;
        opcodes[operation] = opcode;
        left_nodes[operation] = left;
        right_fields[operation] = right_value;
        offset += 3;
    }

    double[MAX_NODES] adjoints;
    bool[MAX_NODES] ancestors;
    for (usz index = 0; index < node_count; index++) {
        adjoints[index] = 0.0;
        ancestors[index] = false;
    }
    adjoints[target] = 1.0;
    ancestors[target] = true;
    long cursor = (long)(target - leaves + 1);
    while (cursor > 0) {
        cursor -= 1;
        usz operation = (usz)cursor;
        usz output_node = leaves + operation;
        if (!ancestors[output_node]) continue;
        usz left = left_nodes[operation];
        double adjoint = adjoints[output_node];
        ancestors[left] = true;
        long opcode = opcodes[operation];
        if (opcode == 0) {
            usz right = (usz)right_fields[operation];
            ancestors[right] = true;
            adjoints[left] += adjoint;
            adjoints[right] += adjoint;
        } else if (opcode == 1) {
            usz right = (usz)right_fields[operation];
            ancestors[right] = true;
            adjoints[left] += adjoint;
            adjoints[right] -= adjoint;
        } else if (opcode == 2) {
            usz right = (usz)right_fields[operation];
            ancestors[right] = true;
            adjoints[left] += nodes[right] * adjoint;
            adjoints[right] += nodes[left] * adjoint;
        } else if (opcode == 3) {
            usz right = (usz)right_fields[operation];
            double left_value = nodes[left];
            double right_value = nodes[right];
            ancestors[right] = true;
            adjoints[left] += (1.0 / right_value) * adjoint;
            adjoints[right] += (-left_value / (right_value * right_value)) * adjoint;
        } else {
            usz exponent = (usz)right_fields[operation];
            double local_derivative = (double)exponent * integer_power(nodes[left], exponent - 1);
            adjoints[left] += local_derivative * adjoint;
        }
    }
    if (!ancestors[source] || adjoints[source] != adjoints[source] ||
        adjoints[source] < -1.0e300 || adjoints[source] > 1.0e300) {
        return INVALID_RESULT;
    }
    return adjoints[source];
}

fn double automatic_differentiation(long* input, usz length)
    @export("automatic_differentiation") {
    return automatic_differentiation_impl(input, length);
}
