module tree_matching;

const usz MAX_NODES = 64;
const usz MAX_INPUT_VALUES = 2 + 3 * (MAX_NODES - 1);
const usz MATRIX_SIZE = MAX_NODES * MAX_NODES;

fn void matching_dp(usz node, long parent, usz count, bool* adjacent, long* weights,
        bool* visited, long* parent_of, long* without_edge, long* with_edge, usz* reached) {
    visited[node] = true;
    parent_of[node] = parent;
    *reached = *reached + 1;
    long base = 0;
    for (usz child = 0; child < count; child++) {
        if (adjacent[node * MAX_NODES + child] && (long)child != parent && !visited[child]) {
            matching_dp(child, (long)node, count, adjacent, weights, visited, parent_of,
                without_edge, with_edge, reached);
            long child_best = without_edge[child] > with_edge[child] ? without_edge[child] : with_edge[child];
            base += child_best;
        }
    }
    without_edge[node] = base;
    with_edge[node] = 0;
    for (usz child = 0; child < count; child++) {
        if (parent_of[child] == (long)node) {
            long child_best = without_edge[child] > with_edge[child] ? without_edge[child] : with_edge[child];
            long candidate = base - child_best + without_edge[child] + weights[node * MAX_NODES + child];
            if (candidate > with_edge[node]) with_edge[node] = candidate;
        }
    }
}

fn long tree_matching(long* values, usz length) @export("tree_matching") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES || values[0] < 1 || values[0] > (long)MAX_NODES) return -1;
    usz count = (usz)values[0];
    if (length != 2 + 3 * (count - 1) || values[1] < 0 || values[1] >= (long)count) return -1;
    bool[MATRIX_SIZE] adjacent;
    long[MATRIX_SIZE] weights;
    for (usz i = 0; i < MATRIX_SIZE; i++) { adjacent[i] = false; weights[i] = 0; }
    for (usz edge = 0; edge < count - 1; edge++) {
        long a_value = values[2 + 3 * edge], b_value = values[3 + 3 * edge], weight = values[4 + 3 * edge];
        if (a_value < 0 || b_value < 0 || a_value >= (long)count || b_value >= (long)count ||
            a_value == b_value || weight < 0 || weight > 1000) return -1;
        usz a = (usz)a_value, b = (usz)b_value;
        usz ab = a * MAX_NODES + b, ba = b * MAX_NODES + a;
        if (adjacent[ab]) return -1;
        adjacent[ab] = true; adjacent[ba] = true;
        weights[ab] = weight; weights[ba] = weight;
    }
    bool[MAX_NODES] visited;
    long[MAX_NODES] parent_of, without_edge, with_edge;
    for (usz node = 0; node < MAX_NODES; node++) {
        visited[node] = false; parent_of[node] = -2;
        without_edge[node] = 0; with_edge[node] = 0;
    }
    usz reached = 0;
    usz root = (usz)values[1];
    matching_dp(root, -1, count, &adjacent[0], &weights[0], &visited[0], &parent_of[0],
        &without_edge[0], &with_edge[0], &reached);
    if (reached != count) return -1;
    return without_edge[root] > with_edge[root] ? without_edge[root] : with_edge[root];
}
