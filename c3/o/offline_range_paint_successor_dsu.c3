module offline_range_paint_successor_dsu;

const long MAX_N = 64;
const long MAX_Q = 64;

fn usz find_successor(long* parent, usz node) {
    usz root = node;
    while ((usz)parent[root] != root) root = (usz)parent[root];
    while ((usz)parent[node] != node) { usz next = (usz)parent[node]; parent[node] = (long)root; node = next; }
    return root;
}

fn long offline_range_paint_successor_dsu(long* input, usz length) @export("offline_range_paint_successor_dsu") {
    if (input == null || length < 2 || length > 195) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 3 * q) return -1;
    long[64] left, right, color;
    for (usz j = 0; j < q; j++) {
        left[j] = input[2 + 3 * j]; right[j] = input[3 + 3 * j]; color[j] = input[4 + 3 * j];
        if (left[j] < 0 || left[j] > right[j] || right[j] >= n_value || color[j] < -1000 || color[j] > 1000) return -1;
    }
    long[65] parent;
    long[64] final_color = zeroed;
    for (usz i = 0; i <= n; i++) parent[i] = (long)i;
    usz operation = q;
    while (operation > 0) {
        operation--;
        usz cell = find_successor(parent, (usz)left[operation]);
        while (cell <= (usz)right[operation]) {
            final_color[cell] = color[operation];
            parent[cell] = (long)find_successor(parent, cell + 1);
            cell = find_successor(parent, cell);
        }
    }
    long checksum = 0;
    for (usz i = 0; i < n; i++) checksum += (long)(i + 1) * (final_color[i] + 1001);
    return checksum;
}
