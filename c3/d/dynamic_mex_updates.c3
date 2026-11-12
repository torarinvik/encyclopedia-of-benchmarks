module dynamic_mex_updates;

const MAX_N = 32;
const MAX_Q = 32;
const MAX_OUTPUT_BYTES = 8 * MAX_Q;

fn void tree_set(int* tree, usz base, usz value, int present) {
    usz node = base + value;
    tree[node] = present;
    node /= 2;
    while (node > 0) {
        tree[node] = tree[2 * node] + tree[2 * node + 1];
        node /= 2;
    }
}

fn usz find_mex(int* tree, usz base, usz domain_size) {
    usz node = 1, start = 0, span = base;
    while (span > 1) {
        usz half = span / 2;
        usz left_width = 0;
        if (start < domain_size) left_width = domain_size - start < half ? domain_size - start : half;
        if ((usz)tree[2 * node] < left_width) {
            node *= 2;
            span = half;
        } else {
            node = 2 * node + 1;
            start += half;
            span = half;
        }
    }
    return start;
}

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long dynamic_mex_updates(long* input, usz length, char* output, usz capacity)
    @export("dynamic_mex_updates") {
    if (input == null || length < 2 || length > 99) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + n + 2 * q) return -1;
    long[MAX_N] current, update_values;
    usz[MAX_Q] update_indices;
    for (usz i = 0; i < n; i++) {
        long value = input[2 + i];
        if (value < -1000 || value > 1000) return -1;
        current[i] = value;
    }
    usz cursor = 2 + n;
    for (usz i = 0; i < q; i++) {
        long index = input[cursor], value = input[cursor + 1];
        cursor += 2;
        if (index < 0 || index >= n_value || value < -1000 || value > 1000) return -1;
        update_indices[i] = (usz)index;
        update_values[i] = value;
    }
    usz needed = 8 * q;
    if (needed > 0 && (output == null || capacity < needed)) return -2;
    usz base = 1;
    while (base < n + 1) base *= 2;
    int[MAX_N + 1] frequencies = {};
    int[2 * (2 * MAX_N)] tree = {};
    for (usz i = 0; i < n; i++)
        if (current[i] >= 0 && current[i] <= n_value) frequencies[(usz)current[i]]++;
    for (usz value = 0; value < n + 1; value++)
        tree[base + value] = if frequencies[value] > 0: 1 else: 0;
    usz node = base;
    while node > 1 {
        node--;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }
    char[MAX_OUTPUT_BYTES] staged;
    for (usz op = 0; op < q; op++) {
        usz index = update_indices[op];
        long old_value = current[index], new_value = update_values[op];
        if (old_value != new_value) {
            if (old_value >= 0 && old_value <= n_value) {
                usz old_index = (usz)old_value;
                frequencies[old_index]--;
                if (frequencies[old_index] == 0) tree_set(&tree[0], base, old_index, 0);
            }
            if (new_value >= 0 && new_value <= n_value) {
                usz new_index = (usz)new_value;
                if (frequencies[new_index] == 0) tree_set(&tree[0], base, new_index, 1);
                frequencies[new_index]++;
            }
            current[index] = new_value;
        }
        write_i64(&staged[0], 8 * op, (long)find_mex(&tree[0], base, n + 1));
    }
    for (usz byte = 0; byte < needed; byte++) output[byte] = staged[byte];
    return (long)needed;
}
