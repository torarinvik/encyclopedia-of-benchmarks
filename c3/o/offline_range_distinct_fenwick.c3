module offline_range_distinct_fenwick;

fn void ordf_add(long* tree, long n, long position, long delta) {
    for (long i = position+1; i <= n; i += i & -i) tree[i] += delta;
}

fn long ordf_prefix(long* tree, long end) {
    long result = 0;
    while (end > 0) { result += tree[end]; end &= end-1; }
    return result;
}

fn long offline_range_distinct_fenwick(long* input, usz length) @export("offline_range_distinct_fenwick") {
    if (input == null || length < 3 || length > 195) return -1;
    long n = input[0], q = input[1];
    if (n < 1 || n > 64 || q < 0 || q > 64 || length != (2+n+2*q).usz()) return -1;
    for (long i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] > 255) return -1;
    long[65] head;
    long[65] tree = {0};
    long[64] next;
    long[256] last;
    for (long i = 0; i < 65; i++) head[i] = -1;
    for (long i = 0; i < 256; i++) last[i] = -1;
    for (long i = 0; i < q; i++) {
        long left = input[2+n+2*i], right = input[3+n+2*i];
        if (left < 0 || left > right || right > n) return -1;
        next[i] = head[right]; head[right] = i;
    }
    long result = 0;
    for (long right = 0; right <= n; right++) {
        if (right > 0) {
            long value = input[1+right];
            if (last[value] >= 0) ordf_add(&tree[0], n, last[value], -1);
            ordf_add(&tree[0], n, right-1, 1); last[value] = right-1;
        }
        for (long query = head[right]; query >= 0; query = next[query]) {
            long left = input[2+n+2*query];
            result += (query+1) * (ordf_prefix(&tree[0],right)-ordf_prefix(&tree[0],left));
        }
    }
    return result;
}
