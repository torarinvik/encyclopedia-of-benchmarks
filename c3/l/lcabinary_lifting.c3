module lcabinary_lifting;

const usz MAX_NODES = 128;
const usz MAX_EDGES = 127;
const usz MAX_DIRECTED_EDGES = 254;
const usz MAX_QUERIES = 256;
const usz MAX_LEVELS = 7;
const usz MAX_PARSEABLE_INPUT_VALUES = 771;

fn int dsu_find(int* parent, int node) {
    int root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        int parent_node = parent[node];
        parent[node] = root;
        node = parent_node;
    }
    return root;
}

fn int lca_query(int left_arg, int right_arg, int* depth, int* up, usz levels) {
    int left = left_arg, right = right_arg;
    if (depth[left] < depth[right]) { int temporary = left; left = right; right = temporary; }
    uint difference = (uint)(depth[left] - depth[right]);
    for (usz level = 0; level < levels; level++) {
        if ((difference & (1u << level)) != 0) left = up[(usz)left * MAX_LEVELS + level];
    }
    if (left == right) return left;
    for (usz level = levels; level > 0; level--) {
        usz column = level - 1;
        int left_ancestor = up[(usz)left * MAX_LEVELS + column];
        int right_ancestor = up[(usz)right * MAX_LEVELS + column];
        if (left_ancestor != right_ancestor) { left = left_ancestor; right = right_ancestor; }
    }
    return up[(usz)left * MAX_LEVELS];
}

fn long lca_binary_lifting_benchmark(long* input, usz length) @export("lca_binary_lifting_benchmark") {
    if (input == null || length < 4 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_NODES) return -1;
    usz node_count = (usz)input[0];
    if (input[1] < 0 || input[1] >= (long)node_count) return -1;
    int root = (int)input[1];
    if (input[2] != (long)(node_count - 1)) return -1;
    usz edge_count = node_count - 1;
    usz cursor = 3;
    if (cursor + 2 * edge_count + 1 > length) return -1;

    int[MAX_NODES] parent = {};
    int[MAX_NODES] ranks = zeroed;
    int[MAX_NODES] head;
    for (usz node = 0; node < node_count; node++) { parent[node] = (int)node; head[node] = -1; }
    int[MAX_DIRECTED_EDGES] edge_to;
    int[MAX_DIRECTED_EDGES] edge_next;
    usz directed_edge_count = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_value = input[cursor++];
        long right_value = input[cursor++];
        if (left_value < 0 || left_value >= (long)node_count ||
            right_value < 0 || right_value >= (long)node_count || left_value == right_value) return -1;
        int left = (int)left_value;
        int right = (int)right_value;
        int left_root = dsu_find(&parent[0], left);
        int right_root = dsu_find(&parent[0], right);
        if (left_root == right_root) return -1;
        if (ranks[left_root] < ranks[right_root]) parent[left_root] = right_root;
        else if (ranks[left_root] > ranks[right_root]) parent[right_root] = left_root;
        else { parent[right_root] = left_root; ranks[left_root]++; }

        edge_to[directed_edge_count] = right;
        edge_next[directed_edge_count] = head[left];
        head[left] = (int)directed_edge_count++;
        edge_to[directed_edge_count] = left;
        edge_next[directed_edge_count] = head[right];
        head[right] = (int)directed_edge_count++;
    }
    int component = dsu_find(&parent[0], 0);
    for (usz node = 1; node < node_count; node++)
        if (dsu_find(&parent[0], (int)node) != component) return -1;

    long query_count_value = input[cursor++];
    if (query_count_value < 0 || query_count_value > (long)MAX_QUERIES) return -1;
    usz query_count = (usz)query_count_value;
    if (cursor + 2 * query_count != length) return -1;

    int[MAX_NODES] depth;
    int[MAX_NODES] ancestors;
    int[MAX_NODES] queue;
    for (usz node = 0; node < node_count; node++) { depth[node] = -1; ancestors[node] = -1; }
    depth[root] = 0;
    ancestors[root] = root;
    usz queue_head = 0, queue_tail = 0;
    queue[queue_tail++] = root;
    while (queue_head < queue_tail) {
        int node = queue[queue_head++];
        for (int edge_index = head[node]; edge_index >= 0; edge_index = edge_next[edge_index]) {
            int child = edge_to[edge_index];
            if (child == ancestors[node]) continue;
            if (ancestors[child] >= 0) return -1;
            ancestors[child] = node;
            depth[child] = depth[node] + 1;
            queue[queue_tail++] = child;
        }
    }
    if (queue_tail != node_count) return -1;

    usz levels = 0;
    while ((1u << levels) < node_count) levels++;
    int[MAX_NODES * MAX_LEVELS] up = {};
    for (usz node = 0; node < node_count; node++) up[node * MAX_LEVELS] = ancestors[node];
    for (usz level = 1; level < levels; level++) {
        for (usz node = 0; node < node_count; node++) {
            int previous = up[node * MAX_LEVELS + level - 1];
            up[node * MAX_LEVELS + level] = up[(usz)previous * MAX_LEVELS + level - 1];
        }
    }

    long checksum = 0;
    for (usz query = 0; query < query_count; query++) {
        long left_value = input[cursor++];
        long right_value = input[cursor++];
        if (left_value < 0 || left_value >= (long)node_count ||
            right_value < 0 || right_value >= (long)node_count) return -1;
        int ancestor = lca_query((int)left_value, (int)right_value, &depth[0], &up[0], levels);
        checksum += (long)(query + 1) * ((long)ancestor + 1);
    }
    return checksum;
}
