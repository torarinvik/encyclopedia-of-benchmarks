module range_union_find;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_PARSEABLE_LENGTH = 99;

fn usz find_root(long* parent, usz vertex) {
    while (parent[vertex] >= 0) {
        usz ancestor = (usz)parent[vertex];
        if (parent[ancestor] >= 0) parent[vertex] = parent[ancestor];
        vertex = ancestor;
    }
    return vertex;
}

fn usz unite_roots(long* parent, long* left, long* right, usz root_a, usz root_b) {
    if (parent[root_a] > parent[root_b]) { usz temporary = root_a; root_a = root_b; root_b = temporary; }
    parent[root_a] += parent[root_b];
    parent[root_b] = (long)root_a;
    if (left[root_b] < left[root_a]) left[root_a] = left[root_b];
    if (right[root_b] > right[root_a]) right[root_a] = right[root_b];
    return root_a;
}

fn long range_union_find(long* values, usz length) @export("range_union_find") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = values[0], q_value = values[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q ||
        length != 2 + 3 * (usz)q_value) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    for (usz operation = 0; operation < q; operation++) {
        usz offset = 2 + 3 * operation;
        long opcode = values[offset], first = values[offset + 1], second = values[offset + 2];
        if (opcode == 0) { if (first < 0 || first > second || second > n_value) return -1; }
        else if (opcode == 1) { if (first < 0 || first >= n_value || second < 0 || second >= n_value) return -1; }
        else if (opcode == 2) { if (first < 0 || first >= n_value || second != 0) return -1; }
        else return -1;
    }
    long[MAX_N] parent; long[MAX_N] left; long[MAX_N] right;
    for (usz vertex = 0; vertex < n; vertex++) { parent[vertex] = -1; left[vertex] = (long)vertex; right[vertex] = (long)vertex + 1; }
    long components = (long)n, total = 0;
    for (usz operation = 0; operation < q; operation++) {
        usz offset = 2 + 3 * operation;
        long opcode = values[offset]; usz first = (usz)values[offset + 1], second = (usz)values[offset + 2];
        long observed = 0;
        if (opcode == 0) {
            if (first < second) {
                usz root = find_root(parent, first), next = (usz)right[root];
                while (next < second) {
                    usz next_root = find_root(parent, next);
                    if (root == next_root) break;
                    root = unite_roots(parent, left, right, root, next_root);
                    components--;
                    next = (usz)right[root];
                }
            }
            observed = components;
        } else if (opcode == 1) observed = find_root(parent, first) == find_root(parent, second) ? 1 : 0;
        else observed = -parent[find_root(parent, first)];
        total += (long)(operation + 1) * observed;
    }
    return total;
}
