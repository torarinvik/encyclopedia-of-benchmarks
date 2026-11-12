module unionfind_with_potential;

const long MAX_N = 64;
const long MAX_Q = 256;
const long MODULUS = 998244353;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn usz find_root(long* parent, long* difference, usz item) {
    if ((usz)parent[item] != item) {
        usz old_parent = (usz)parent[item];
        usz root = find_root(parent, difference, old_parent);
        difference[item] = normalize(difference[item] + difference[old_parent]);
        parent[item] = (long)root;
    }
    return (usz)parent[item];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long unionfind_with_potential(long* input, usz length, char* output,
    usz capacity) @export("unionfind_with_potential") {
    if (input == null || length < 6 || length > 2 + 4 * (usz)MAX_Q) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 4 * q) return -1;

    for (usz operation = 0; operation < q; operation += 1) {
        usz position = 2 + 4 * operation;
        long kind = input[position], u = input[position + 1];
        long v = input[position + 2], x = input[position + 3];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            if (x < 0 || x >= MODULUS) return -1;
        } else if (kind == 1) {
            if (x != 0) return -1;
        } else return -1;
    }
    usz required = 8 * q;
    if (output == null || capacity < required) return -2;

    long parent[MAX_N], set_size[MAX_N], difference[MAX_N];
    for (usz item = 0; item < n; item += 1) {
        parent[item] = (long)item;
        set_size[item] = 1;
        difference[item] = 0;
    }
    for (usz operation = 0; operation < q; operation += 1) {
        usz position = 2 + 4 * operation;
        long kind = input[position];
        usz u = (usz)input[position + 1], v = (usz)input[position + 2];
        long x = input[position + 3], answer;
        usz root_u = find_root(parent, difference, u);
        usz root_v = find_root(parent, difference, v);
        if (kind == 1) {
            answer = root_u == root_v ? normalize(difference[u] - difference[v]) : -1;
        } else if (root_u == root_v) {
            answer = normalize(difference[u] - difference[v]) == x ? 1 : 0;
        } else if (set_size[root_u] < set_size[root_v]) {
            parent[root_u] = (long)root_v;
            difference[root_u] = normalize(x - difference[u] + difference[v]);
            set_size[root_v] += set_size[root_u];
            answer = 1;
        } else {
            parent[root_v] = (long)root_u;
            difference[root_v] = normalize(difference[u] - difference[v] - x);
            set_size[root_u] += set_size[root_v];
            answer = 1;
        }
        store_i64_le(output, 8 * operation, answer);
    }
    return (long)required;
}
