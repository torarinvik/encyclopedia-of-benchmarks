#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 127

static int validate_tree(const int64_t *values, size_t count, size_t root)
{
    uint8_t parents[MAX_NODES] = {0};
    uint8_t seen[MAX_NODES] = {0};
    int64_t stack[MAX_NODES];
    size_t top = 0, visited = 0;
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 2 + 3 * i;
        const int64_t value = values[base];
        const int64_t left = values[base + 1], right = values[base + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= count) || (right >= 0 && (uint64_t)right >= count)) return 0;
        if (left >= 0 && ++parents[(size_t)left] > 1) return 0;
        if (right >= 0 && ++parents[(size_t)right] > 1) return 0;
    }
    for (size_t i = 0; i < count; ++i)
        if (parents[i] != (i == root ? 0 : 1)) return 0;
    stack[top++] = (int64_t)root;
    while (top > 0) {
        const size_t index = (size_t)stack[--top];
        if (seen[index]) return 0;
        seen[index] = 1;
        ++visited;
        const size_t base = 2 + 3 * index;
        const int64_t left = values[base + 1], right = values[base + 2];
        if (left >= 0) stack[top++] = left;
        if (right >= 0) stack[top++] = right;
    }
    return visited == count;
}

static size_t decimal_length(int64_t value)
{
    size_t length = value < 0 ? 1 : 0;
    uint64_t magnitude = value < 0 ? (uint64_t)(-value) : (uint64_t)value;
    do { ++length; magnitude /= 10; } while (magnitude != 0);
    return length;
}

static void append_value(int32_t value, uint8_t *output, size_t *position)
{
    char digits[10];
    size_t count = 0;
    int64_t remaining = value;
    uint64_t magnitude;
    if (remaining < 0) { output[(*position)++] = '-'; magnitude = (uint64_t)(-remaining); }
    else magnitude = (uint64_t)remaining;
    do { digits[count++] = (char)('0' + magnitude % 10); magnitude /= 10; } while (magnitude != 0);
    while (count > 0) output[(*position)++] = (uint8_t)digits[--count];
}

static void emit_node(const int64_t *values, size_t index, uint8_t *output, size_t *position)
{
    const size_t base = 2 + 3 * index;
    const int32_t value = (int32_t)values[base];
    const int64_t left = values[base + 1], right = values[base + 2];
    append_value(value, output, position);
    if (left >= 0) { output[(*position)++] = '('; emit_node(values, (size_t)left, output, position); output[(*position)++] = ')'; }
    else if (right >= 0) { output[(*position)++] = '('; output[(*position)++] = ')'; }
    if (right >= 0) { output[(*position)++] = '('; emit_node(values, (size_t)right, output, position); output[(*position)++] = ')'; }
}

int64_t binary_tree_to_string(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2) return -1;
    if (values[0] < 0 || values[0] > MAX_NODES) return -1;
    const size_t count = (size_t)values[0];
    if (length != 2 + 3 * count) return -1;
    const int64_t root = values[1];
    if (count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (uint64_t)root >= count || !validate_tree(values, count, (size_t)root)) return -1;
    size_t required = 2 * (count - 1);
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 2 + 3 * i;
        required += decimal_length(values[base]);
        if (values[base + 1] == -1 && values[base + 2] >= 0) required += 2;
    }
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    emit_node(values, (size_t)root, output, &position);
    return (int64_t)position;
}
