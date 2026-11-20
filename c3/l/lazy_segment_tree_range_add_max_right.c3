module lazy_segment_tree_range_add_max_right;

const usz MAX_VALID_LENGTH = 66;
const usz MAX_PARSEABLE_LENGTH = 67;

fn void apply(long* tree, long* lazy, usz node, usz segment_length, long delta) {
    tree[node] += delta * (long)segment_length;
    lazy[node] += delta;
}

fn void push(long* tree, long* lazy, usz node, usz segment_length) {
    if (segment_length > 1 && lazy[node] != 0) {
        usz half = segment_length / 2;
        apply(tree, lazy, 2 * node, half, lazy[node]);
        apply(tree, lazy, 2 * node + 1, half, lazy[node]);
        lazy[node] = 0;
    }
}

fn void range_add(long* tree, long* lazy, usz node, usz low, usz high,
                  usz query_low, usz query_high, long delta) {
    if (query_low >= query_high) return;
    if (query_high <= low || high <= query_low) return;
    if (query_low <= low && high <= query_high) {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    usz middle = (low + high) / 2;
    if (query_low < middle) range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle) range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

fn usz max_right(long* tree, long* lazy, usz node, usz low, usz high,
                 usz n, usz left, long limit, long* accumulated) {
    if (high <= left) return high;
    if (low >= n) return n;
    if (left <= low && high <= n && *accumulated + tree[node] <= limit) {
        *accumulated += tree[node];
        return high;
    }
    if (high - low == 1) return low;
    push(tree, lazy, node, high - low);
    usz middle = (low + high) / 2;
    usz first = max_right(tree, lazy, 2 * node, low, middle, n, left, limit, accumulated);
    if (first < middle && first >= left) return first;
    return max_right(tree, lazy, 2 * node + 1, middle, high, n, left, limit, accumulated);
}

fn long lazy_segment_tree_range_add_max_right(long* input, usz length) @export("lazy_segment_tree_range_add_max_right") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    usz n = (usz)input[0];
    usz operations = (usz)input[1];
    if (length != 2 + n + 4 * operations || length > MAX_VALID_LENGTH) return -1;
    for (usz i = 0; i < n; i++) if (input[2 + i] < 0 || input[2 + i] > 31) return -1;
    for (usz op = 0; op < operations; op++) {
        usz p = 2 + n + 4 * op;
        long opcode = input[p], left = input[p + 1], right = input[p + 2], extra = input[p + 3];
        if (opcode == 0) {
            if (left < 0 || left > (long)n || right < left || right > (long)n || extra < 0 || extra > 31) return -1;
        } else if (opcode == 1) {
            if (left < 0 || left > (long)n || right < 0 || right > 8192 || extra != 0) return -1;
        } else return -1;
    }

    usz base = 1;
    while (base < n) base *= 2;
    long[64] tree;
    long[64] lazy;
    for (usz i = 0; i < 64; i++) { tree[i] = 0; lazy[i] = 0; }
    for (usz i = 0; i < n; i++) tree[base + i] = input[2 + i];
    for (usz node = base; node > 1;) { node--; tree[node] = tree[2 * node] + tree[2 * node + 1]; }

    usz query_index = 0;
    long result = 0;
    for (usz op = 0; op < operations; op++) {
        usz p = 2 + n + 4 * op;
        usz left = (usz)input[p + 1], right = (usz)input[p + 2];
        if (input[p] == 0) range_add(&tree[0], &lazy[0], 1, 0, base, left, right, input[p + 3]);
        else {
            long accumulated = 0;
            usz boundary = max_right(&tree[0], &lazy[0], 1, 0, base, n, left, (long)right, &accumulated);
            result |= (long)boundary << (5 * query_index);
            query_index++;
        }
    }
    return result;
}
