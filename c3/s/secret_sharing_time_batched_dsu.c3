module secret_sharing_time_batched_dsu;

const usz MAX_N = 16;
const usz MAX_PARSEABLE_LENGTH = 64;

fn usz secret_find(usz* parent, usz node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn void secret_join(usz* parent, usz* sizes, usz left, usz right) {
    usz a = secret_find(parent, left), b = secret_find(parent, right);
    if (a == b) return;
    if (sizes[a] < sizes[b]) { usz swap = a; a = b; b = swap; }
    parent[b] = a;
    sizes[a] += sizes[b];
}

fn long secret_sharing_time_batched_dsu(long* input, usz length)
        @export("secret_sharing_time_batched_dsu") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0], first_value = input[1], m_value = input[2];
    if (n_value < 2 || n_value > (long)MAX_N || first_value < 1 || first_value >= n_value
        || m_value < 0 || m_value > 20) return -1;
    usz n = (usz)n_value, first = (usz)first_value, m = (usz)m_value;
    if (length != 3 + 3 * m) return -1;
    for (usz i = 0; i < m; i++) {
        long u = input[3 + 3 * i], v = input[4 + 3 * i], time = input[5 + 3 * i];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || u == v || time < 1 || time > 20)
            return -1;
    }
    usz[MAX_N] parent, sizes;
    for (usz i = 0; i < n; i++) { parent[i] = i; sizes[i] = 1; }
    secret_join(&parent[0], &sizes[0], 0, first);
    for (usz time = 1; time <= 20; time++) {
        bool[MAX_N] touched = zeroed;
        for (usz i = 0; i < m; i++) {
            usz u = (usz)input[3 + 3 * i], v = (usz)input[4 + 3 * i];
            if (input[5 + 3 * i] == (long)time) {
                secret_join(&parent[0], &sizes[0], u, v);
                touched[u] = true;
                touched[v] = true;
            }
        }
        usz known_root = secret_find(&parent[0], 0);
        for (usz node = 0; node < n; node++) {
            if (touched[node] && secret_find(&parent[0], node) != known_root) {
                parent[node] = node;
                sizes[node] = 1;
            }
        }
    }
    usz known_root = secret_find(&parent[0], 0);
    long result = 0;
    for (usz node = 0; node < n; node++)
        if (secret_find(&parent[0], node) == known_root) result |= 1L << node;
    return result;
}
