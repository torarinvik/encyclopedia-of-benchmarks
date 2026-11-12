module persistent_unionfind;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_INPUT_VALUES = 2 + 4 * MAX_Q;

fn usz find_root(usz[MAX_N]* parent, usz item) {
    while (parent[item] != item) item = parent[item];
    return item;
}

fn void visit_version(usz node, long[MAX_Q]* kind, long[MAX_Q]* u, long[MAX_Q]* v,
    long[MAX_Q + 1]* first_child, long[MAX_Q]* next_sibling,
    usz[MAX_N]* parent, usz[MAX_N]* set_size, long[MAX_Q + 1]* answer,
    long[MAX_Q]* history_child, long[MAX_Q]* history_root, long[MAX_Q]* history_size,
    usz* history_count) {
    usz saved_history = *history_count;
    if (node != 0) {
        usz operation = node - 1;
        if (kind[operation] == 0) {
            usz root_u = find_root(parent, (usz)u[operation]);
            usz root_v = find_root(parent, (usz)v[operation]);
            if (root_u == root_v) {
                history_child[*history_count] = -1;
                history_root[*history_count] = -1;
                history_size[*history_count] = 0;
            } else {
                if (set_size[root_u] > set_size[root_v]) {
                    usz temporary = root_u;
                    root_u = root_v;
                    root_v = temporary;
                }
                history_child[*history_count] = (long)root_u;
                history_root[*history_count] = (long)root_v;
                history_size[*history_count] = (long)set_size[root_v];
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
            }
            *history_count += 1;
        } else {
            answer[node] = find_root(parent, (usz)u[operation]) ==
                           find_root(parent, (usz)v[operation]) ? 1 : 0;
        }
    }
    long child = first_child[node];
    while (child >= 0) {
        visit_version((usz)child, kind, u, v, first_child, next_sibling,
                      parent, set_size, answer, history_child, history_root,
                      history_size, history_count);
        child = next_sibling[(usz)child - 1];
    }
    while (*history_count > saved_history) {
        *history_count -= 1;
        long changed_child = history_child[*history_count];
        if (changed_child >= 0) {
            usz root = (usz)history_root[*history_count];
            parent[(usz)changed_child] = (usz)changed_child;
            set_size[root] = (usz)history_size[*history_count];
        }
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long persistent_unionfind(long* input, usz length, char* output, usz capacity)
    @export("persistent_unionfind") {
    if (input == null || length < 6 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 4 * q) return -1;

    long[MAX_Q] kind, u, v, next_sibling;
    long[MAX_Q + 1] first_child, answer = zeroed;
    for (usz node = 0; node <= q; node += 1) first_child[node] = -1;
    usz query_count = 0;
    for (usz operation = 0; operation < q; operation += 1) {
        usz offset = 2 + 4 * operation;
        kind[operation] = input[offset];
        long version = input[offset + 1];
        u[operation] = input[offset + 2];
        v[operation] = input[offset + 3];
        if ((kind[operation] != 0 && kind[operation] != 1) || version < -1 ||
            version >= (long)operation || u[operation] < 0 || u[operation] >= n_value ||
            v[operation] < 0 || v[operation] >= n_value) return -1;
        if (version >= 0 && kind[(usz)version] != 0) return -1;
        if (kind[operation] == 1) query_count += 1;
        usz parent_node = (usz)(version + 1);
        next_sibling[operation] = first_child[parent_node];
        first_child[parent_node] = (long)(operation + 1);
    }

    usz required = 8 * query_count;
    if (output == null || capacity < required) return -2;
    usz[MAX_N] parent, set_size;
    for (usz item = 0; item < n; item += 1) {
        parent[item] = item;
        set_size[item] = 1;
    }
    long[MAX_Q] history_child, history_root, history_size;
    usz history_count = 0;
    visit_version(0, &kind, &u, &v, &first_child, &next_sibling, &parent,
                  &set_size, &answer, &history_child, &history_root,
                  &history_size, &history_count);
    usz written = 0;
    for (usz operation = 0; operation < q; operation += 1) {
        if (kind[operation] == 1) {
            store_i64_le(output, written, answer[operation + 1]);
            written += 8;
        }
    }
    return (long)written;
}
