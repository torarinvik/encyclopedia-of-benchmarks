module online_bipartiteness_dsu;

const long MAX_N = 32;
const long MAX_Q = 64;

fn usz find_parity(long* parent, long* parity, usz node, long* xor_to_root) {
    usz root = node;
    long total = 0;
    while ((usz)parent[root] != root) { total ^= parity[root]; root = (usz)parent[root]; }
    usz current = node;
    long accumulated = 0;
    while ((usz)parent[current] != current) {
        usz next = (usz)parent[current];
        long edge = parity[current];
        parent[current] = (long)root;
        parity[current] = total ^ accumulated;
        accumulated ^= edge;
        current = next;
    }
    *xor_to_root = total;
    return root;
}

fn long online_bipartiteness_dsu(long* input, usz length) @export("online_bipartiteness_dsu") {
    if (input == null || length < 2 || length > 195) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 3 * q) return -1;
    for (usz j = 0; j < q; j++) {
        long opcode = input[2 + 3 * j], a = input[3 + 3 * j], b = input[4 + 3 * j];
        if (opcode == 0) { if (a < 0 || a >= n_value || b < 0 || b >= n_value) return -1; }
        else if (opcode == 1) { if (a < 0 || a >= n_value || b != 0) return -1; }
        else return -1;
    }
    long[32] parent, size, parity, bad = zeroed;
    for (usz i = 0; i < n; i++) { parent[i] = (long)i; size[i] = 1; parity[i] = 0; }
    long checksum = 0, query_ordinal = 0;
    for (usz j = 0; j < q; j++) {
        long opcode = input[2 + 3 * j];
        usz a = (usz)input[3 + 3 * j];
        if (opcode == 1) {
            long ignored = 0;
            usz root = find_parity(parent, parity, a, &ignored);
            long answer = if bad[root] != 0 then 0 else 1;
            checksum += (query_ordinal + 1) * (answer + 1);
            query_ordinal++;
            continue;
        }
        usz b = (usz)input[4 + 3 * j];
        long parity_a = 0, parity_b = 0;
        usz root_a = find_parity(parent, parity, a, &parity_a);
        usz root_b = find_parity(parent, parity, b, &parity_b);
        if (root_a == root_b) { if (parity_a == parity_b) bad[root_a] = 1; continue; }
        if (size[root_a] < size[root_b]) {
            usz old_root = root_a; root_a = root_b; root_b = old_root;
            long old_parity = parity_a; parity_a = parity_b; parity_b = old_parity;
        }
        parent[root_b] = (long)root_a;
        parity[root_b] = parity_a ^ parity_b ^ 1;
        size[root_a] += size[root_b];
        bad[root_a] = bad[root_a] != 0 || bad[root_b] != 0;
    }
    return checksum;
}
