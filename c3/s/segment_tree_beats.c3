module segment_tree_beats;

const usz MAX_ITEMS = 64;
const usz MAX_OPERATIONS = 128;
const usz MAX_INPUT_VALUES = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
const long VALUE_LIMIT = 1000000;
const long INF = 2305843009213693951;
const long QUERY_OFFSET = 8256000001;

struct SegmentNode {
    long sum; long max1; long max2; long min1; long min2; long add;
    usz max_count; usz min_count;
}

fn void stb_pull(SegmentNode* tree, usz node) {
    SegmentNode* left = &tree[2 * node];
    SegmentNode* right = &tree[2 * node + 1];
    SegmentNode* current = &tree[node];
    current.sum = left.sum + right.sum;
    current.add = 0;
    if (left.max1 == right.max1) {
        current.max1 = left.max1;
        current.max2 = left.max2 > right.max2 ? left.max2 : right.max2;
        current.max_count = left.max_count + right.max_count;
    } else if (left.max1 > right.max1) {
        current.max1 = left.max1;
        current.max2 = left.max2 > right.max1 ? left.max2 : right.max1;
        current.max_count = left.max_count;
    } else {
        current.max1 = right.max1;
        current.max2 = left.max1 > right.max2 ? left.max1 : right.max2;
        current.max_count = right.max_count;
    }
    if (left.min1 == right.min1) {
        current.min1 = left.min1;
        current.min2 = left.min2 < right.min2 ? left.min2 : right.min2;
        current.min_count = left.min_count + right.min_count;
    } else if (left.min1 < right.min1) {
        current.min1 = left.min1;
        current.min2 = left.min2 < right.min1 ? left.min2 : right.min1;
        current.min_count = left.min_count;
    } else {
        current.min1 = right.min1;
        current.min2 = left.min1 < right.min2 ? left.min1 : right.min2;
        current.min_count = right.min_count;
    }
}

fn void stb_build(SegmentNode* tree, long* values, usz node, usz low, usz high) {
    if (high - low == 1) {
        long value = values[low];
        tree[node] = {value, value, -INF, value, INF, 0, 1, 1};
        return;
    }
    usz middle = low + (high - low) / 2;
    stb_build(tree, values, 2 * node, low, middle);
    stb_build(tree, values, 2 * node + 1, middle, high);
    stb_pull(tree, node);
}

fn void stb_apply_add(SegmentNode* item, usz length, long delta) {
    item.sum += delta * (long)length;
    item.max1 += delta; item.min1 += delta;
    if (item.max2 != -INF) item.max2 += delta;
    if (item.min2 != INF) item.min2 += delta;
    item.add += delta;
}

fn void stb_apply_chmin(SegmentNode* item, long ceiling) {
    if (item.max1 <= ceiling) return;
    item.sum += (ceiling - item.max1) * (long)item.max_count;
    if (item.min1 == item.max1) item.min1 = ceiling;
    else if (item.min2 == item.max1) item.min2 = ceiling;
    item.max1 = ceiling;
}

fn void stb_apply_chmax(SegmentNode* item, long floor) {
    if (item.min1 >= floor) return;
    item.sum += (floor - item.min1) * (long)item.min_count;
    if (item.max1 == item.min1) item.max1 = floor;
    else if (item.max2 == item.min1) item.max2 = floor;
    item.min1 = floor;
}

fn void stb_push(SegmentNode* tree, usz node, usz low, usz high) {
    if (high - low == 1) return;
    usz middle = low + (high - low) / 2;
    SegmentNode* parent = &tree[node];
    SegmentNode* left = &tree[2 * node];
    SegmentNode* right = &tree[2 * node + 1];
    if (parent.add != 0) {
        stb_apply_add(left, middle - low, parent.add);
        stb_apply_add(right, high - middle, parent.add);
        parent.add = 0;
    }
    if (left.max1 > parent.max1) stb_apply_chmin(left, parent.max1);
    if (right.max1 > parent.max1) stb_apply_chmin(right, parent.max1);
    if (left.min1 < parent.min1) stb_apply_chmax(left, parent.min1);
    if (right.min1 < parent.min1) stb_apply_chmax(right, parent.min1);
}

fn void stb_range_add(SegmentNode* tree, usz node, usz low, usz high, usz ql, usz qr, long delta) {
    if (qr <= low || high <= ql || delta == 0) return;
    if (ql <= low && high <= qr) { stb_apply_add(&tree[node], high - low, delta); return; }
    stb_push(tree, node, low, high);
    usz middle = low + (high - low) / 2;
    stb_range_add(tree, 2 * node, low, middle, ql, qr, delta);
    stb_range_add(tree, 2 * node + 1, middle, high, ql, qr, delta);
    stb_pull(tree, node);
}

fn void stb_range_chmin(SegmentNode* tree, usz node, usz low, usz high, usz ql, usz qr, long ceiling) {
    SegmentNode* item = &tree[node];
    if (qr <= low || high <= ql || item.max1 <= ceiling) return;
    if (ql <= low && high <= qr && item.max2 < ceiling) { stb_apply_chmin(item, ceiling); return; }
    stb_push(tree, node, low, high);
    usz middle = low + (high - low) / 2;
    stb_range_chmin(tree, 2 * node, low, middle, ql, qr, ceiling);
    stb_range_chmin(tree, 2 * node + 1, middle, high, ql, qr, ceiling);
    stb_pull(tree, node);
}

fn void stb_range_chmax(SegmentNode* tree, usz node, usz low, usz high, usz ql, usz qr, long floor) {
    SegmentNode* item = &tree[node];
    if (qr <= low || high <= ql || item.min1 >= floor) return;
    if (ql <= low && high <= qr && item.min2 > floor) { stb_apply_chmax(item, floor); return; }
    stb_push(tree, node, low, high);
    usz middle = low + (high - low) / 2;
    stb_range_chmax(tree, 2 * node, low, middle, ql, qr, floor);
    stb_range_chmax(tree, 2 * node + 1, middle, high, ql, qr, floor);
    stb_pull(tree, node);
}

fn long stb_range_sum(SegmentNode* tree, usz node, usz low, usz high, usz ql, usz qr) {
    if (qr <= low || high <= ql) return 0;
    if (ql <= low && high <= qr) return tree[node].sum;
    stb_push(tree, node, low, high);
    usz middle = low + (high - low) / 2;
    return stb_range_sum(tree, 2 * node, low, middle, ql, qr) +
        stb_range_sum(tree, 2 * node + 1, middle, high, ql, qr);
}

fn long segment_tree_beats(long* values, usz length) @export("segment_tree_beats") {
    if (values == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = values[0];
    if (n_value < 1 || n_value > (long)MAX_ITEMS) return -1;
    usz n = (usz)n_value;
    if (length < n + 2) return -1;
    long q_value = values[n + 1];
    if (q_value < 0 || q_value > (long)MAX_OPERATIONS) return -1;
    usz q = (usz)q_value;
    if (length != n + 2 + 4 * q) return -1;
    for (usz i = 0; i < n; i++) if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (usz i = 0; i < q; i++) {
        usz p = n + 2 + 4 * i;
        long op = values[p], left = values[p + 1], right = values[p + 2], argument = values[p + 3];
        if (op < 0 || op > 3 || left < 0 || left >= right || right > n_value) return -1;
        if (op == 3) { if (argument != 0) return -1; }
        else if (argument < -VALUE_LIMIT || argument > VALUE_LIMIT) return -1;
    }
    SegmentNode[4 * MAX_ITEMS] tree = {};
    stb_build(&tree[0], &values[1], 1, 0, n);
    long checksum = 0, ordinal = 0;
    for (usz i = 0; i < q; i++) {
        usz p = n + 2 + 4 * i;
        usz left = (usz)values[p + 1], right = (usz)values[p + 2];
        long argument = values[p + 3];
        switch (values[p]) {
        case 0: stb_range_chmin(&tree[0], 1, 0, n, left, right, argument); break;
        case 1: stb_range_chmax(&tree[0], 1, 0, n, left, right, argument); break;
        case 2: stb_range_add(&tree[0], 1, 0, n, left, right, argument); break;
        default: ordinal++; checksum += ordinal * (stb_range_sum(&tree[0], 1, 0, n, left, right) + QUERY_OFFSET);
        }
    }
    return checksum;
}
