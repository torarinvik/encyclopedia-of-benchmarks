module vertex_set_path_composite;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const long MODULUS = 998244353;
const usz MAX_INPUT_VALUES = 4 * MAX_N + 4 * MAX_Q;

struct Affine { long a; long b; }
struct Aggregate { Affine forward; Affine backward; }

fn Affine identity() { return {1, 0}; }

fn Affine compose(Affine after, Affine before) {
    return {(after.a * before.a) % MODULUS,
        (after.a * before.b + after.b) % MODULUS};
}

fn Aggregate identity_aggregate() {
    Affine id = identity();
    return {id, id};
}

fn Aggregate combine(Aggregate left, Aggregate right) {
    return {compose(right.forward, left.forward), compose(left.backward, right.backward)};
}

fn usz find_root(usz[MAX_N]* parent, usz item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

fn void update_leaf(Aggregate[2 * MAX_N]* tree, usz base, usz position, Affine value) {
    usz node = base + position;
    tree[node] = {value, value};
    while (node > 1) {
        node >>= 1;
        tree[node] = combine(tree[node << 1], tree[(node << 1) | 1]);
    }
}

fn Aggregate range_query(Aggregate[2 * MAX_N]* tree, usz base, usz left_value, usz right_value) {
    Aggregate prefix = identity_aggregate(), suffix = identity_aggregate();
    usz left = left_value + base, right = right_value + base;
    while (left < right) {
        if ((left & 1) != 0) {
            prefix = combine(prefix, tree[left]);
            left += 1;
        }
        if ((right & 1) != 0) {
            right -= 1;
            suffix = combine(tree[right], suffix);
        }
        left >>= 1;
        right >>= 1;
    }
    return combine(prefix, suffix);
}

fn Affine path_composition(Aggregate[2 * MAX_N]* tree, usz base,
    usz[MAX_N]* parent, usz[MAX_N]* depth, usz[MAX_N]* head,
    usz[MAX_N]* position, usz from_value, usz to_value) {
    Affine left = identity(), right = identity();
    usz from = from_value, to = to_value;
    while (head[from] != head[to]) {
        if (depth[head[from]] >= depth[head[to]]) {
            Aggregate part = range_query(tree, base, position[head[from]], position[from] + 1);
            left = compose(part.backward, left);
            from = parent[head[from]];
        } else {
            Aggregate part = range_query(tree, base, position[head[to]], position[to] + 1);
            right = compose(right, part.forward);
            to = parent[head[to]];
        }
    }
    if (depth[from] >= depth[to]) {
        Aggregate part = range_query(tree, base, position[to], position[from] + 1);
        left = compose(part.backward, left);
    } else {
        Aggregate part = range_query(tree, base, position[from], position[to] + 1);
        right = compose(right, part.forward);
    }
    return compose(right, left);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long vertex_set_path_composite(long* input, usz length, char* output, usz capacity)
    @export("vertex_set_path_composite") {
    if (input == null || length < 8 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 4 * n + 4 * q) return -1;

    Affine[MAX_N] values;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long a = input[2 + 2 * vertex], b = input[3 + 2 * vertex];
        if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
        values[vertex] = {a, b};
    }

    bool[MAX_N][MAX_N] adjacent = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    usz edge_start = 2 + 2 * n;
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = edge_start + 2 * edge;
        long left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        usz root_left = find_root(&dsu_parent, left), root_right = find_root(&dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            usz temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    usz operation_start = edge_start + 2 * (n - 1);
    for (usz query = 0; query < q; query += 1) {
        usz offset = operation_start + 4 * query;
        long kind = input[offset], first = input[offset + 1];
        long second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            if (first < 0 || first >= n_value || second < 1 || second >= MODULUS ||
                third < 0 || third >= MODULUS) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= n_value || second < 0 || second >= n_value ||
                third < 0 || third >= MODULUS) return -1;
        } else return -1;
    }

    usz[MAX_N] parent, depth, subtree, heavy, order, stack;
    usz order_count = 0, top = 1;
    parent[0] = 0;
    subtree[0] = 1;
    heavy[0] = MAX_N;
    stack[0] = 0;
    order[order_count++] = 0;
    while (top > 0) {
        top -= 1;
        usz vertex = stack[top];
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (!adjacent[vertex][neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            subtree[neighbor] = 1;
            heavy[neighbor] = MAX_N;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (usz index = order_count; index > 1; index -= 1) {
        usz vertex = order[index - 1], p = parent[vertex];
        subtree[p] += subtree[vertex];
        if (heavy[p] == MAX_N || subtree[vertex] > subtree[heavy[p]] ||
            (subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p])) heavy[p] = vertex;
    }

    usz[MAX_N] head, position, chain_vertex, chain_head;
    usz chain_count = 1, timer = 0;
    chain_vertex[0] = 0;
    chain_head[0] = 0;
    while (chain_count > 0) {
        chain_count -= 1;
        usz vertex = chain_vertex[chain_count], current_head = chain_head[chain_count];
        while (vertex != MAX_N) {
            head[vertex] = current_head;
            position[vertex] = timer++;
            for (usz child = 0; child < n; child += 1) {
                if (adjacent[vertex][child] && parent[child] == vertex && child != heavy[vertex]) {
                    chain_vertex[chain_count] = child;
                    chain_head[chain_count++] = child;
                }
            }
            vertex = heavy[vertex];
        }
    }

    usz base = 1;
    while (base < n) base <<= 1;
    Aggregate[2 * MAX_N] tree;
    for (usz node = 0; node < 2 * base; node += 1) tree[node] = identity_aggregate();
    for (usz vertex = 0; vertex < n; vertex += 1)
        update_leaf(&tree, base, position[vertex], values[vertex]);

    long[MAX_Q] answers;
    usz answer_count = 0;
    for (usz query = 0; query < q; query += 1) {
        usz offset = operation_start + 4 * query;
        long kind = input[offset];
        usz first = (usz)input[offset + 1];
        long second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            values[first] = {second, third};
            update_leaf(&tree, base, position[first], values[first]);
        } else {
            Affine combined = path_composition(&tree, base, &parent, &depth, &head, &position,
                first, (usz)second);
            answers[answer_count++] = (combined.a * third + combined.b) % MODULUS;
        }
    }

    usz required = 8 * answer_count;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < answer_count; index += 1)
        store_i64_le(output, 8 * index, answers[index]);
    return (long)required;
}
