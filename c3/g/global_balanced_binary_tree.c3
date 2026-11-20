module global_balanced_binary_tree;

const usz GBST_MAX_N = 64;
const usz GBST_MAX_PARSEABLE_LENGTH = 65;

fn long gbst_build_interval(usz lo, usz hi, long* path, long* prefix,
                            long* gbst_parent, long* left_child,
                            long* right_child, long* local_size) {
    long total_weight = prefix[hi] - prefix[lo];
    usz low = lo, high = hi;
    while (high - low > 1) {
        usz middle = (low + high) / 2;
        if (2 * (prefix[middle] - prefix[lo]) <= total_weight)
            low = middle;
        else
            high = middle;
    }

    usz pivot = low;
    long node = path[pivot];
    local_size[(usz)node] = (long)(hi - lo);
    if (lo < pivot) {
        long child = gbst_build_interval(lo, pivot, path, prefix, gbst_parent,
                                         left_child, right_child, local_size);
        left_child[(usz)node] = child;
        gbst_parent[(usz)child] = node;
    }
    if (pivot + 1 < hi) {
        long child = gbst_build_interval(pivot + 1, hi, path, prefix, gbst_parent,
                                         left_child, right_child, local_size);
        right_child[(usz)node] = child;
        gbst_parent[(usz)child] = node;
    }
    return node;
}

fn long global_balanced_binary_tree(long* input, usz length)
    @export("global_balanced_binary_tree")
{
    if (input == null || length < 1 || length > GBST_MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)GBST_MAX_N) return -1;
    if (length != (usz)n_value) return -1;
    usz n = (usz)n_value;

    long[GBST_MAX_N] parent;
    long[GBST_MAX_N] subtree_size;
    long[GBST_MAX_N] heavy_child;
    long[GBST_MAX_N] gbst_parent;
    long[GBST_MAX_N] left_child;
    long[GBST_MAX_N] right_child;
    long[GBST_MAX_N] local_size;
    long[GBST_MAX_N] path;
    long[GBST_MAX_N + 1] prefix;
    for (usz vertex = 0; vertex < n; vertex++) {
        parent[vertex] = -1;
        subtree_size[vertex] = 1;
        heavy_child[vertex] = -1;
        gbst_parent[vertex] = -1;
        left_child[vertex] = -1;
        right_child[vertex] = -1;
        local_size[vertex] = 0;
    }
    for (usz vertex = 1; vertex < n; vertex++) {
        long p = input[vertex];
        if (p < 0 || p >= (long)vertex) return -1;
        parent[vertex] = p;
    }

    usz cursor = n;
    while (cursor > 1) {
        cursor -= 1;
        usz p = (usz)parent[cursor];
        subtree_size[p] += subtree_size[cursor];
    }
    for (usz vertex = 1; vertex < n; vertex++) {
        usz p = (usz)parent[vertex];
        long current = heavy_child[p];
        if (current < 0 || subtree_size[vertex] > subtree_size[(usz)current])
            heavy_child[p] = (long)vertex;
    }

    for (usz head = 0; head < n; head++) {
        if (head > 0 && heavy_child[(usz)parent[head]] == (long)head) continue;
        usz path_length = 0;
        long vertex = (long)head;
        prefix[0] = 0;
        while (vertex >= 0) {
            usz node = (usz)vertex;
            long child = heavy_child[node];
            long weight = subtree_size[node] -
                          (child >= 0 ? subtree_size[(usz)child] : 0);
            path[path_length] = vertex;
            prefix[path_length + 1] = prefix[path_length] + weight;
            path_length += 1;
            vertex = child;
        }
        long root = gbst_build_interval(0, path_length, &path[0], &prefix[0],
                                        &gbst_parent[0], &left_child[0],
                                        &right_child[0], &local_size[0]);
        gbst_parent[(usz)root] = head == 0 ? -1 : parent[head];
    }

    long checksum = 0;
    for (usz vertex = 0; vertex < n; vertex++) {
        long record = (gbst_parent[vertex] + 1)
            + 65 * (left_child[vertex] + 1)
            + 4225 * (right_child[vertex] + 1)
            + 274625 * local_size[vertex];
        checksum += ((long)vertex + 1) * record;
    }
    return checksum;
}
