module binary_tree_to_string;

const usz MAX_NODES = 127;

fn bool validate_tree(long* values, usz count, usz root) {
    u8[127] parents = {0};
    bool[127] seen = {0};
    long[127] stack;
    usz top = 0, visited = 0;
    for (usz i = 0; i < count; i++) {
        usz base = 2 + 3 * i;
        long value = values[base], left = values[base + 1], right = values[base + 2];
        if (value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= count) || (right >= 0 && (usz)right >= count)) return false;
        if (left >= 0 && ++parents[(usz)left] > 1) return false;
        if (right >= 0 && ++parents[(usz)right] > 1) return false;
    }
    for (usz i = 0; i < count; i++)
        if (parents[i] != (i == root ? 0 : 1)) return false;
    stack[top++] = (long)root;
    while (top > 0) {
        usz index = (usz)stack[--top];
        if (seen[index]) return false;
        seen[index] = true;
        visited++;
        usz base = 2 + 3 * index;
        long left = values[base + 1], right = values[base + 2];
        if (left >= 0) stack[top++] = left;
        if (right >= 0) stack[top++] = right;
    }
    return visited == count;
}

fn usz decimal_length(long value) {
    usz length = value < 0 ? 1 : 0;
    ulong magnitude = value < 0 ? (ulong)(-value) : (ulong)value;
    do { length++; magnitude /= 10; } while (magnitude != 0);
    return length;
}

fn void append_value(long value, char* output, usz* position) {
    char[10] digits;
    usz count = 0;
    ulong magnitude;
    if (value < 0) { output[(*position)++] = '-'; magnitude = (ulong)(-value); }
    else magnitude = (ulong)value;
    do { digits[count++] = (char)('0' + magnitude % 10); magnitude /= 10; } while (magnitude != 0);
    while (count > 0) output[(*position)++] = digits[--count];
}

fn void emit_node(long* values, usz index, char* output, usz* position) {
    usz base = 2 + 3 * index;
    long value = values[base], left = values[base + 1], right = values[base + 2];
    append_value(value, output, position);
    if (left >= 0) { output[(*position)++] = '('; emit_node(values, (usz)left, output, position); output[(*position)++] = ')'; }
    else if (right >= 0) { output[(*position)++] = '('; output[(*position)++] = ')'; }
    if (right >= 0) { output[(*position)++] = '('; emit_node(values, (usz)right, output, position); output[(*position)++] = ')'; }
}

fn long binary_tree_to_string(long* values, usz length, char* output, usz output_capacity)
    @export("binary_tree_to_string")
{
    if (values == null || length < 2 || values[0] < 0 || values[0] > 127) return -1;
    usz count = (usz)values[0];
    if (length != 2 + 3 * count) return -1;
    long root = values[1];
    if (count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (usz)root >= count || !validate_tree(values, count, (usz)root)) return -1;
    usz required = 2 * (count - 1);
    for (usz i = 0; i < count; i++) {
        usz base = 2 + 3 * i;
        required += decimal_length(values[base]);
        if (values[base + 1] == -1 && values[base + 2] >= 0) required += 2;
    }
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    emit_node(values, (usz)root, output, &position);
    return (long)position;
}
