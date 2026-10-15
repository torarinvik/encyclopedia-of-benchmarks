module lowest_common_ancestor_tarjan;

const usz MAX_NODE_COUNT = 256;
const usz MAX_QUERY_COUNT = 1024;
const usz MAX_ADJACENCY_COUNT = 2 * (MAX_NODE_COUNT - 1);
const usz MAX_QUERY_ADJACENCY_COUNT = 2 * MAX_QUERY_COUNT;

fn usz find_root(usz* parent, usz node) {
    usz root = node;
    while (parent[root] != root) root = parent[root];
    usz current = node;
    while (parent[current] != current) {
        usz next = parent[current];
        parent[current] = root;
        current = next;
    }
    return root;
}

fn void unite(usz* parent, usz* rank, usz left, usz right) {
    usz left_root = find_root(parent, left);
    usz right_root = find_root(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) parent[left_root] = right_root;
    else if (rank[left_root] > rank[right_root]) parent[right_root] = left_root;
    else { parent[right_root] = left_root; rank[left_root]++; }
}

fn long lowest_common_ancestor_tarjan(long* input, usz length, char* output,
    usz output_capacity) @export("lowest_common_ancestor_tarjan") {
    if (input == null || length < 4 || input[0] < 1 || input[0] > (long)MAX_NODE_COUNT) return -1;
    usz node_count = (usz)input[0];
    if (input[1] < 0 || input[1] >= (long)node_count || input[2] != (long)(node_count - 1) ||
        input[3] < 0 || input[3] > (long)MAX_QUERY_COUNT) return -1;
    usz root = (usz)input[1];
    usz edge_count = (usz)input[2];
    usz query_count = (usz)input[3];
    if (length != 4 + 2 * edge_count + 2 * query_count) return -1;

    usz[MAX_NODE_COUNT] validation_parent;
    usz[MAX_NODE_COUNT] dsu_parent;
    usz[MAX_NODE_COUNT] ancestor;
    usz[MAX_NODE_COUNT] validation_rank;
    usz[MAX_NODE_COUNT] dsu_rank;
    long[MAX_NODE_COUNT] edge_head;
    long[MAX_ADJACENCY_COUNT] edge_to;
    long[MAX_ADJACENCY_COUNT] edge_next;
    long[MAX_NODE_COUNT] query_head;
    long[MAX_QUERY_ADJACENCY_COUNT] query_to;
    long[MAX_QUERY_ADJACENCY_COUNT] query_next;
    long[MAX_QUERY_ADJACENCY_COUNT] query_id;
    long[MAX_QUERY_COUNT] answers;
    long[MAX_NODE_COUNT] tree_parent;
    long[MAX_NODE_COUNT] cursor;
    bool[MAX_NODE_COUNT] visited;
    bool[MAX_NODE_COUNT] finished;
    usz[MAX_NODE_COUNT] stack;
    for (usz node = 0; node < node_count; node++) {
        validation_parent[node] = node;
        dsu_parent[node] = node;
        ancestor[node] = node;
        edge_head[node] = -1;
        query_head[node] = -1;
        tree_parent[node] = -1;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_arg = input[4 + 2 * edge];
        long right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (long)node_count ||
            right_arg >= (long)node_count || left_arg == right_arg) return -1;
        usz left = (usz)left_arg;
        usz right = (usz)right_arg;
        if (find_root(&validation_parent[0], left) == find_root(&validation_parent[0], right)) return -1;
        unite(&validation_parent[0], &validation_rank[0], left, right);
        usz forward = 2 * edge;
        usz reverse = forward + 1;
        edge_to[forward] = (long)right;
        edge_next[forward] = edge_head[left];
        edge_head[left] = (long)forward;
        edge_to[reverse] = (long)left;
        edge_next[reverse] = edge_head[right];
        edge_head[right] = (long)reverse;
    }
    usz root_component = find_root(&validation_parent[0], root);
    for (usz node = 0; node < node_count; node++)
        if (find_root(&validation_parent[0], node) != root_component) return -1;
    for (usz query = 0; query < query_count; query++) {
        long left_arg = input[4 + 2 * edge_count + 2 * query];
        long right_arg = input[5 + 2 * edge_count + 2 * query];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (long)node_count || right_arg >= (long)node_count)
            return -1;
        usz left = (usz)left_arg;
        usz right = (usz)right_arg;
        usz first = 2 * query;
        usz second = first + 1;
        query_to[first] = (long)right;
        query_id[first] = (long)query;
        query_next[first] = query_head[left];
        query_head[left] = (long)first;
        query_to[second] = (long)left;
        query_id[second] = (long)query;
        query_next[second] = query_head[right];
        query_head[right] = (long)second;
    }
    if (query_count > output_capacity || (query_count != 0 && output == null)) return -2;

    usz top = 1;
    stack[0] = root;
    visited[root] = true;
    cursor[root] = edge_head[root];
    while (top > 0) {
        usz node = stack[top - 1];
        long edge = cursor[node];
        if (edge >= 0) {
            cursor[node] = edge_next[(usz)edge];
            usz child = (usz)edge_to[(usz)edge];
            if ((long)child == tree_parent[node]) continue;
            if (visited[child]) return -1;
            visited[child] = true;
            tree_parent[child] = (long)node;
            cursor[child] = edge_head[child];
            stack[top] = child;
            top++;
            continue;
        }
        finished[node] = true;
        long item = query_head[node];
        while (item >= 0) {
            usz index = (usz)item;
            usz other = (usz)query_to[index];
            if (finished[other]) answers[(usz)query_id[index]] =
                (long)ancestor[find_root(&dsu_parent[0], other)];
            item = query_next[index];
        }
        top--;
        if (tree_parent[node] >= 0) {
            usz parent = (usz)tree_parent[node];
            unite(&dsu_parent[0], &dsu_rank[0], parent, node);
            usz component = find_root(&dsu_parent[0], parent);
            ancestor[component] = parent;
        }
    }
    for (usz query = 0; query < query_count; query++) output[query] = (char)answers[query];
    return (long)query_count;
}
