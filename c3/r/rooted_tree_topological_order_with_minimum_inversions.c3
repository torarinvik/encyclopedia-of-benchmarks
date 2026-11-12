module rooted_tree_topological_order_with_minimum_inversions;

const int MAX_N = 12;
const int MAX_OUTPUT_WORDS = MAX_N + 1;
const usz MAX_INPUT_VALUES = 3 * (usz)MAX_N + 1;
const long MAX_WEIGHT = 1000000;

fn int compare_ratio(long left_c, long left_d, long right_c, long right_d) {
    bool left_zero = left_c == 0 && left_d == 0;
    bool right_zero = right_c == 0 && right_d == 0;
    if (left_zero != right_zero) return left_zero ? -1 : 1;
    long lhs = left_c * right_d, rhs = left_d * right_c;
    if (lhs > rhs) return 1;
    if (lhs < rhs) return -1;
    return 0;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long rooted_tree_topological_order_with_minimum_inversions(long* input,
    usz length, char* output, usz capacity) @export("rooted_tree_topological_order_with_minimum_inversions") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long nv = input[0];
    if (nv < 1 || nv > MAX_N || length != 3 * (usz)nv) return -1;
    int n = (int)nv;

    int[MAX_N] tree_parent;
    for (int vertex = 1; vertex < n; vertex++) {
        long p = input[vertex];
        if (p < 0 || p >= (long)vertex) return -1;
        tree_parent[vertex] = (int)p;
    }

    long[MAX_N] original_c, original_d, aggregate_c, aggregate_d;
    long sum_c = 0, sum_d = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        long c = input[n + vertex], d = input[2 * n + vertex];
        if (c < 0 || c > MAX_WEIGHT || d < 0 || d > MAX_WEIGHT) return -1;
        sum_c += c;
        sum_d += d;
        if (sum_c > MAX_WEIGHT || sum_d > MAX_WEIGHT) return -1;
        original_c[vertex] = aggregate_c[vertex] = c;
        original_d[vertex] = aggregate_d[vertex] = d;
    }

    int[MAX_N] dsu_parent, component_label, link;
    bool[MAX_N] active;
    for (int vertex = 0; vertex < n; vertex++) {
        dsu_parent[vertex] = vertex;
        component_label[vertex] = vertex;
        active[vertex] = vertex != 0;
        link[vertex] = vertex;
    }

    for (int step = 0; step < n - 1; step++) {
        int selected = -1;
        for (int candidate = 1; candidate < n; candidate++) {
            if (!active[candidate]) continue;
            if (selected < 0) { selected = candidate; continue; }
            int comparison = compare_ratio(aggregate_c[candidate], aggregate_d[candidate],
                                           aggregate_c[selected], aggregate_d[selected]);
            if (comparison > 0 || (comparison == 0 && candidate > selected)) selected = candidate;
        }
        if (selected < 0) return -1;
        int parent_component = tree_parent[selected];
        while (dsu_parent[parent_component] != parent_component)
            parent_component = dsu_parent[parent_component];
        int target = component_label[parent_component];
        int child_component = selected;
        while (dsu_parent[child_component] != child_component)
            child_component = dsu_parent[child_component];
        if (child_component == parent_component) return -1;
        aggregate_c[target] += aggregate_c[selected];
        aggregate_d[target] += aggregate_d[selected];
        dsu_parent[child_component] = parent_component;
        component_label[parent_component] = target;
        active[selected] = false;
        if (target != 0) active[target] = true;
        int next = link[selected];
        link[selected] = link[target];
        link[target] = next;
    }

    int[MAX_N] traversal;
    int count = 0, vertex = link[0];
    while (count < n) {
        traversal[count++] = vertex;
        if (vertex == 0) break;
        vertex = link[vertex];
    }
    if (count != n || traversal[count - 1] != 0) return -1;

    long[MAX_OUTPUT_WORDS] words;
    long prefix_d = 0, objective = 0;
    for (int index = 0; index < n; index++) {
        int ordered_vertex = traversal[n - 1 - index];
        words[index + 1] = ordered_vertex;
        objective += prefix_d * original_c[ordered_vertex];
        prefix_d += original_d[ordered_vertex];
    }
    words[0] = objective;
    usz output_bytes = 8 * (usz)(n + 1);
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < (usz)(n + 1); word++)
        store_i64_le(output, 8 * word, words[word]);
    return (long)output_bytes;
}
