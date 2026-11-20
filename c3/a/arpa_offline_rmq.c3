module arpa_offline_rmq;

const long MAX_N = 64;
const long MAX_Q = 64;

fn usz find_root(long* parent, usz node) {
    usz root = node;
    while ((usz)parent[root] != root) root = (usz)parent[root];
    while ((usz)parent[node] != node) { usz next = (usz)parent[node]; parent[node] = (long)root; node = next; }
    return root;
}

fn long arpa_offline_rmq(long* input, usz length) @export("arpa_offline_rmq") {
    if (input == null || length < 2 || length > 195) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (usz i = 0; i < n; i++) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;
    usz query_start = 2 + n;
    for (usz j = 0; j < q; j++) {
        long left = input[query_start + 2 * j], right = input[query_start + 2 * j + 1];
        if (left < 0 || left > right || right >= n_value) return -1;
    }
    long[64] parent, stack, head, next_query;
    for (usz i = 0; i < n; i++) { parent[i] = (long)i; head[i] = -1; }
    for (usz j = 0; j < q; j++) {
        usz right = (usz)input[query_start + 2 * j + 1];
        next_query[j] = head[right];
        head[right] = (long)j;
    }
    usz stack_size = 0;
    long checksum = 0;
    for (usz right = 0; right < n; right++) {
        while (stack_size > 0 && input[2 + (usz)stack[stack_size - 1]] > input[2 + right])
            parent[(usz)stack[--stack_size]] = (long)right;
        stack[stack_size++] = (long)right;
        for (long query = head[right]; query >= 0; query = next_query[(usz)query]) {
            usz j = (usz)query;
            usz node = (usz)input[query_start + 2 * j];
            usz answer = find_root(parent, node);
            checksum += (long)(j + 1) * (long)(answer + 1);
        }
    }
    return checksum;
}
