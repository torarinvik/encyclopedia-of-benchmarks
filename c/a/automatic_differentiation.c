/* Scalar reverse-mode port of TheAlgorithms/Python automatic_differentiation.py. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LEAVES 32
#define MAX_OPERATIONS 64
#define MAX_NODES (MAX_LEAVES + MAX_OPERATIONS)
#define INVALID_RESULT (-1e300)

static double integer_power(double value, int exponent) {
    double result = 1.0;
    for (int index = 0; index < exponent; ++index) result *= value;
    return result;
}

double automatic_differentiation(const int64_t *input, size_t length) {
    if (input == NULL || length < 8) return INVALID_RESULT;
    int64_t leaves_value = input[0], operations_value = input[1];
    if (leaves_value < 1 || leaves_value > MAX_LEAVES ||
        operations_value < 1 || operations_value > MAX_OPERATIONS ||
        length != 4 + (size_t)leaves_value + 3 * (size_t)operations_value)
        return INVALID_RESULT;
    size_t leaves = (size_t)leaves_value, operations = (size_t)operations_value;
    int64_t target_value = input[2], source_value = input[3];
    size_t node_count = leaves + operations;
    if (target_value < (int64_t)leaves || target_value >= (int64_t)node_count ||
        source_value < 0 || source_value >= (int64_t)leaves) return INVALID_RESULT;
    size_t target = (size_t)target_value, source = (size_t)source_value;

    double nodes[MAX_NODES] = {0.0};
    int64_t opcodes[MAX_OPERATIONS], left_nodes[MAX_OPERATIONS], right_fields[MAX_OPERATIONS];
    for (size_t index = 0; index < leaves; ++index) {
        int64_t value = input[4 + index];
        if (value < -16 || value > 16) return INVALID_RESULT;
        nodes[index] = (double)value;
    }
    size_t offset = 4 + leaves;
    for (size_t operation = 0; operation < operations; ++operation) {
        int64_t opcode = input[offset], left_value = input[offset + 1], right_value = input[offset + 2];
        size_t output_node = leaves + operation;
        if (left_value < 0 || left_value >= (int64_t)output_node) return INVALID_RESULT;
        size_t left = (size_t)left_value;
        double result;
        if (opcode == 5) {
            if (right_value < 1 || right_value > 8) return INVALID_RESULT;
            result = integer_power(nodes[left], (int)right_value);
        } else {
            if (opcode < 0 || opcode > 3 || right_value < 0 || right_value >= (int64_t)output_node)
                return INVALID_RESULT;
            double right = nodes[(size_t)right_value];
            if (opcode == 0) result = nodes[left] + right;
            else if (opcode == 1) result = nodes[left] - right;
            else if (opcode == 2) result = nodes[left] * right;
            else {
                if (right == 0.0) return INVALID_RESULT;
                result = nodes[left] / right;
            }
        }
        if (!isfinite(result) || fabs(result) > 10000000000.0) return INVALID_RESULT;
        nodes[output_node] = result;
        opcodes[operation] = opcode;
        left_nodes[operation] = left_value;
        right_fields[operation] = right_value;
        offset += 3;
    }

    double adjoints[MAX_NODES] = {0.0};
    uint8_t ancestors[MAX_NODES] = {0};
    adjoints[target] = 1.0;
    ancestors[target] = 1;
    for (size_t cursor = target - leaves + 1; cursor > 0; --cursor) {
        size_t operation = cursor - 1;
        size_t output_node = leaves + operation;
        if (!ancestors[output_node]) continue;
        int64_t opcode = opcodes[operation];
        size_t left = (size_t)left_nodes[operation];
        double adjoint = adjoints[output_node];
        ancestors[left] = 1;
        if (opcode == 0) {
            size_t right = (size_t)right_fields[operation];
            ancestors[right] = 1;
            adjoints[left] += adjoint;
            adjoints[right] += adjoint;
        } else if (opcode == 1) {
            size_t right = (size_t)right_fields[operation];
            ancestors[right] = 1;
            adjoints[left] += adjoint;
            adjoints[right] -= adjoint;
        } else if (opcode == 2) {
            size_t right = (size_t)right_fields[operation];
            ancestors[right] = 1;
            adjoints[left] += nodes[right] * adjoint;
            adjoints[right] += nodes[left] * adjoint;
        } else if (opcode == 3) {
            size_t right = (size_t)right_fields[operation];
            double left_value = nodes[left], right_value = nodes[right];
            ancestors[right] = 1;
            adjoints[left] += (1.0 / right_value) * adjoint;
            adjoints[right] += (-left_value / (right_value * right_value)) * adjoint;
        } else {
            int exponent = (int)right_fields[operation];
            double local_derivative = (double)exponent * integer_power(nodes[left], exponent - 1);
            adjoints[left] += local_derivative * adjoint;
        }
    }
    if (!ancestors[source] || !isfinite(adjoints[source]) || fabs(adjoints[source]) > 1e300)
        return INVALID_RESULT;
    return adjoints[source];
}
