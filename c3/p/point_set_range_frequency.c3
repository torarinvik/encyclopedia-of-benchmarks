module point_set_range_frequency;

const int MAX_N = 64;
const int MAX_Q = 64;
const int MAX_VALUES = MAX_N + MAX_Q;
const int STRIDE = MAX_N + 1;
const int MAX_TREE = MAX_VALUES * STRIDE;
const usz MAX_PARSEABLE_INPUT = 2 + (usz)MAX_N + 4 * (usz)MAX_Q + 1;
const long MAX_VALUE = 1000000;

struct Operation { long kind, a, b, c; }

fn usz lowbit(usz value) { return value & (~value + 1); }

fn usz lower_bound_long(long* values, usz count, long target) {
    usz left = 0, right = count;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn usz sort_unique(long* values, usz count) {
    for (usz index = 1; index < count; index++) {
        long value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = value;
    }
    usz unique_count = 0;
    for (usz index = 0; index < count; index++) {
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    }
    return unique_count;
}

fn void fenwick_add(long* tree, usz value_id, usz position, usz n, long delta) {
    usz index = position + 1;
    usz row = value_id * STRIDE;
    while (index <= n) {
        tree[row + index] += delta;
        index += lowbit(index);
    }
}

fn long fenwick_prefix(long* tree, usz value_id, usz count) {
    long total = 0;
    usz index = count, row = value_id * STRIDE;
    while (index > 0) {
        total += tree[row + index];
        index -= lowbit(index);
    }
    return total;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long point_set_range_frequency(long* input, usz length, char* output, usz capacity)
    @export("point_set_range_frequency") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (2 + n > length) return -1;
    long[MAX_VALUES] values;
    long[MAX_N] initial;
    Operation[MAX_Q] operations;
    usz value_count = 0;
    for (usz index = 0; index < n; index++) {
        long value = input[2 + index];
        if (value < 0 || value > MAX_VALUE) return -1;
        initial[index] = value;
        values[value_count++] = value;
    }
    usz cursor = 2 + n, query_count = 0;
    for (usz index = 0; index < q; index++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 2 > length) return -1;
            long position = input[cursor], value = input[cursor + 1];
            cursor += 2;
            if (position < 0 || position >= n_value || value < 0 || value > MAX_VALUE) return -1;
            operations[index] = {kind, position, value, 0};
            values[value_count++] = value;
        } else if (kind == 1) {
            if (cursor + 3 > length) return -1;
            long left = input[cursor], right = input[cursor + 1], value = input[cursor + 2];
            cursor += 3;
            if (left < 0 || left > right || right > n_value || value < 0 || value > MAX_VALUE) return -1;
            operations[index] = {kind, left, right, value};
            query_count++;
        } else return -1;
    }
    if (cursor != length) return -1;
    usz output_bytes = 8 * query_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;

    usz unique_count = sort_unique(&values[0], value_count);
    long[MAX_TREE] tree;
    for (usz index = 0; index < MAX_TREE; index++) tree[index] = 0;
    usz[MAX_N] current;
    for (usz index = 0; index < n; index++) {
        current[index] = lower_bound_long(&values[0], unique_count, initial[index]);
        fenwick_add(&tree[0], current[index], index, n, 1);
    }
    usz answer = 0;
    for (usz index = 0; index < q; index++) {
        Operation operation = operations[index];
        if (operation.kind == 0) {
            usz position = (usz)operation.a;
            usz next = lower_bound_long(&values[0], unique_count, operation.b);
            if (current[position] != next) {
                fenwick_add(&tree[0], current[position], position, n, -1);
                fenwick_add(&tree[0], next, position, n, 1);
                current[position] = next;
            }
        } else {
            usz id = lower_bound_long(&values[0], unique_count, operation.c);
            long count = 0;
            if (id < unique_count && values[id] == operation.c)
                count = fenwick_prefix(&tree[0], id, (usz)operation.b) -
                        fenwick_prefix(&tree[0], id, (usz)operation.a);
            store_i64_le(output, 8 * answer++, count);
        }
    }
    return (long)output_bytes;
}
