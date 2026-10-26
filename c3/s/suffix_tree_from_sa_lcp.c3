module suffix_tree_from_sa_lcp;

const usz MAX_TEXT = 8;
const usz MAX_INPUT = 10;
const usz MAX_SUFFIXES = 9;
const usz MAX_NODES = 17;
const usz MAX_OUTPUT_WORDS = 86;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn int symbol_at(long* input, int n, int position) {
    return position == n ? 0 : (int)input[position + 1];
}

fn bool suffix_less(long* input, int n, int left, int right) {
    int total = n + 1;
    while (left < total && right < total) {
        int a = symbol_at(input, n, left), b = symbol_at(input, n, right);
        if (a != b) return a < b;
        left += 1; right += 1;
    }
    return left == total && right != total;
}

fn long suffix_tree_from_sa_lcp(long* input, usz length, char* output, usz capacity) @export("suffix_tree_from_sa_lcp") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long n_raw = input[0];
    if (n_raw < 0 || n_raw > (long)MAX_TEXT || length != (usz)n_raw + 1) return -1;
    int n = (int)n_raw;
    for (int i = 0; i < n; i += 1) if (input[i + 1] < 1 || input[i + 1] > 255) return -1;

    int suffix_count = n + 1;
    int[MAX_SUFFIXES] suffix_array = zeroed;
    int[MAX_SUFFIXES] lcp = zeroed;
    for (int i = 0; i < suffix_count; i += 1) suffix_array[i] = i;
    for (int i = 1; i < suffix_count; i += 1) {
        int value = suffix_array[i], j = i;
        while (j > 0 && suffix_less(input, n, value, suffix_array[j - 1])) {
            suffix_array[j] = suffix_array[j - 1]; j -= 1;
        }
        suffix_array[j] = value;
    }
    for (int rank = 1; rank < suffix_count; rank += 1) {
        int left = suffix_array[rank - 1], right = suffix_array[rank], common = 0;
        while (left + common < suffix_count && right + common < suffix_count
            && symbol_at(input, n, left + common) == symbol_at(input, n, right + common)) common += 1;
        lcp[rank] = common;
    }

    int[MAX_NODES] parent = zeroed, depth = zeroed, representative = zeroed, leaf = zeroed, last_child = zeroed;
    int[MAX_NODES] stack = zeroed;
    int node_count = 1, stack_size = 1;
    parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1; last_child[0] = -1;
    stack[0] = 0;
    for (int rank = 0; rank < suffix_count; rank += 1) {
        if (rank > 0) {
            int common = lcp[rank];
            while (stack_size > 1 && depth[stack[stack_size - 1]] > common) stack_size -= 1;
            int top = stack[stack_size - 1];
            if (depth[top] < common) {
                int old_child = last_child[top];
                if (old_child < 0) return -1;
                int internal = node_count; node_count += 1;
                parent[internal] = top; depth[internal] = common;
                representative[internal] = representative[old_child]; leaf[internal] = -1;
                last_child[internal] = old_child;
                parent[old_child] = internal; last_child[top] = internal;
                stack[stack_size] = internal; stack_size += 1;
            }
        }
        int owner = stack[stack_size - 1];
        int suffix_start = suffix_array[rank];
        int new_leaf = node_count; node_count += 1;
        parent[new_leaf] = owner; depth[new_leaf] = suffix_count - suffix_start;
        representative[new_leaf] = suffix_start; leaf[new_leaf] = suffix_start;
        last_child[new_leaf] = -1; last_child[owner] = new_leaf;
    }

    long[MAX_NODES][5] records = zeroed;
    for (int node = 0; node < node_count; node += 1) {
        if (node == 0) {
            records[node][0] = -1; records[node][1] = -1; records[node][2] = -1; records[node][3] = 0; records[node][4] = -1;
        } else {
            int p = parent[node];
            records[node][0] = representative[p]; records[node][1] = depth[p];
            records[node][2] = representative[node]; records[node][3] = depth[node]; records[node][4] = leaf[node];
        }
    }
    for (int i = 1; i < node_count; i += 1) {
        long[5] value = {records[i][0], records[i][1], records[i][2], records[i][3], records[i][4]};
        int j = i;
        while (j > 0 && (value[3] < records[j - 1][3]
            || (value[3] == records[j - 1][3] && value[2] < records[j - 1][2])
            || (value[3] == records[j - 1][3] && value[2] == records[j - 1][2] && value[4] < records[j - 1][4]))) {
            for (int k = 0; k < 5; k += 1) records[j][k] = records[j - 1][k];
            j -= 1;
        }
        for (int k = 0; k < 5; k += 1) records[j][k] = value[k];
    }
    long[MAX_OUTPUT_WORDS] staged = zeroed;
    staged[0] = node_count;
    usz words = 1;
    for (int node = 0; node < node_count; node += 1)
        for (int field = 0; field < 5; field += 1) { staged[words] = records[node][field]; words += 1; }
    usz bytes = words * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < words; word += 1) store_i64_le(output, word * 8, staged[word]);
    return (long)bytes;
}
