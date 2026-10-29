module rooted_tree_isomorphism_classification;

const usz MAX_TREES = 16;
const usz MAX_TREE_VERTICES = 32;
const usz MAX_TOTAL_VERTICES = 128;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES;

struct TreeSignature { usz child_count; usz[MAX_TREE_VERTICES] child_types; }

fn usz rooted_tree_isomorphism_intern(TreeSignature* signatures, usz* signature_count,
                                      usz* children, usz child_count) {
    for (usz signature = 0; signature < *signature_count; signature++) {
        if (signatures[signature].child_count != child_count) continue;
        usz index = 0;
        while (index < child_count && signatures[signature].child_types[index] == children[index]) index++;
        if (index == child_count) return signature;
    }
    if (*signature_count >= MAX_TOTAL_VERTICES) return MAX_TOTAL_VERTICES;
    usz result = *signature_count;
    signatures[result].child_count = child_count;
    for (usz index = 0; index < child_count; index++) signatures[result].child_types[index] = children[index];
    *signature_count = *signature_count + 1;
    return result;
}

fn long rooted_tree_isomorphism_canonical_root(uint* adjacency, usz n, usz root,
    TreeSignature* signatures, usz* signature_count) {
    usz[MAX_TREE_VERTICES] parent = {};
    usz[MAX_TREE_VERTICES] order = {};
    usz[MAX_TREE_VERTICES] stack = {};
    usz[MAX_TREE_VERTICES] type = {};
    bool[MAX_TREE_VERTICES] visited = {};
    for (usz vertex = 0; vertex < n; vertex++) parent[vertex] = MAX_TREE_VERTICES;
    parent[root] = root;
    visited[root] = true;
    usz stack_size = 1, order_size = 0;
    stack[0] = root;
    while (stack_size != 0) {
        stack_size--;
        usz vertex = stack[stack_size];
        order[order_size] = vertex;
        order_size++;
        for (usz neighbor = 0; neighbor < n; neighbor++) {
            uint bit = (uint)1 << (uint)neighbor;
            if ((adjacency[vertex] & bit) == 0 || neighbor == parent[vertex]) continue;
            if (visited[neighbor]) return -1;
            visited[neighbor] = true;
            parent[neighbor] = vertex;
            stack[stack_size] = neighbor;
            stack_size++;
        }
    }
    if (order_size != n) return -1;
    for (usz reverse = order_size; reverse > 0; reverse--) {
        usz vertex = order[reverse - 1];
        usz[MAX_TREE_VERTICES] children = {};
        usz child_count = 0;
        for (usz candidate = 0; candidate < n; candidate++) {
            if (candidate != vertex && parent[candidate] == vertex) {
                children[child_count] = type[candidate];
                child_count++;
            }
        }
        for (usz index = 1; index < child_count; index++) {
            usz value = children[index], place = index;
            while (place > 0 && children[place - 1] > value) {
                children[place] = children[place - 1];
                place--;
            }
            children[place] = value;
        }
        type[vertex] = rooted_tree_isomorphism_intern(signatures, signature_count, &children[0], child_count);
        if (type[vertex] >= MAX_TOTAL_VERTICES) return -1;
    }
    return (long)type[root];
}

fn long rooted_tree_isomorphism_classification(long* values, usz length,
    char* output, usz output_capacity) @export("rooted_tree_isomorphism_classification") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long tree_count_value = values[0];
    if (tree_count_value < 1 || tree_count_value > (long)MAX_TREES) return -1;
    usz tree_count = (usz)tree_count_value;
    TreeSignature[MAX_TOTAL_VERTICES] signatures = {};
    usz signature_count = 0;
    usz[MAX_TREES] root_types = {};
    uint8[MAX_TREES] labels = {};
    usz position = 1, total_vertices = 0, class_count = 0;
    for (usz tree = 0; tree < tree_count; tree++) {
        if (position + 2 > length) return -1;
        long n_value = values[position++], root_value = values[position++];
        if (n_value < 1 || n_value > (long)MAX_TREE_VERTICES || root_value < 0 || root_value >= n_value) return -1;
        usz n = (usz)n_value;
        total_vertices += n;
        if (total_vertices > MAX_TOTAL_VERTICES) return -1;
        usz edge_count = n - 1;
        if (2 * edge_count > length - position) return -1;
        uint[MAX_TREE_VERTICES] adjacency = {};
        for (usz edge = 0; edge < edge_count; edge++) {
            long left_value = values[position++], right_value = values[position++];
            if (left_value < 0 || right_value < 0 || left_value >= n_value || right_value >= n_value || left_value == right_value) return -1;
            usz left = (usz)left_value, right = (usz)right_value;
            uint left_bit = (uint)1 << (uint)left, right_bit = (uint)1 << (uint)right;
            if ((adjacency[left] & right_bit) != 0) return -1;
            adjacency[left] |= right_bit;
            adjacency[right] |= left_bit;
        }
        long root_type = rooted_tree_isomorphism_canonical_root(&adjacency[0], n, (usz)root_value,
            &signatures[0], &signature_count);
        if (root_type < 0) return -1;
        root_types[tree] = (usz)root_type;
        usz prior = 0;
        while (prior < tree && root_types[prior] != root_types[tree]) prior++;
        if (prior < tree) labels[tree] = labels[prior];
        else { labels[tree] = (uint8)class_count; class_count++; }
    }
    if (position != length) return -1;
    if (output == null || output_capacity < tree_count) return -2;
    for (usz tree = 0; tree < tree_count; tree++) output[tree] = (char)labels[tree];
    return (long)tree_count;
}
