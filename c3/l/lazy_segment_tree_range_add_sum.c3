module lazy_segment_tree_range_add_sum;

const usz MAX_ITEMS = 256;
const usz MAX_OPERATIONS = 512;
const usz MAX_INPUT_LENGTH = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
const long VALUE_LIMIT = 1000000;
const long QUERY_OFFSET = 131328000001;

fn void apply(long* tree, long* lazy, usz node, usz segment_length, long delta) {
    tree[node] += delta * (long)segment_length;
    lazy[node] += delta;
}

fn void push(long* tree, long* lazy, usz node, usz segment_length) {
    if (segment_length > 1 && lazy[node] != 0) {
        usz child_length = segment_length / 2;
        apply(tree, lazy, 2 * node, child_length, lazy[node]);
        apply(tree, lazy, 2 * node + 1, child_length, lazy[node]);
        lazy[node] = 0;
    }
}

fn void range_add(long* tree, long* lazy, usz node, usz low, usz high,
                  usz query_low, usz query_high, long delta) {
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

fn long range_sum(long* tree, long* lazy, usz node, usz low, usz high,
                  usz query_low, usz query_high) {
    if (query_low <= low && high <= query_high) return tree[node];
    push(tree, lazy, node, high - low);
    usz middle = (low + high) / 2;
    long result = 0;
    if (query_low < middle) result += range_sum(tree, lazy, 2 * node, low, middle, query_low, query_high);
    if (query_high > middle) result += range_sum(tree, lazy, 2 * node + 1, middle, high, query_low, query_high);
    return result;
}

fn long lazy_segment_tree_range_add_sum(long* values, usz length) @export("lazy_segment_tree_range_add_sum") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long item_count_value = values[0];
    if (item_count_value < 1 || item_count_value > (long)MAX_ITEMS) return -1;
    usz item_count = (usz)item_count_value;
    if (length < item_count + 2) return -1;
    long operation_count_value = values[item_count + 1];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    if (length != item_count + 2 + 4 * operation_count) return -1;

    for (usz i = 0; i < item_count; i++)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = item_count + 2 + 4 * operation;
        long opcode = values[position], left = values[position + 1];
        long right = values[position + 2], delta = values[position + 3];
        if (left < 0 || left >= right || right > item_count_value) return -1;
        if (opcode == 0) {
            if (delta < -VALUE_LIMIT || delta > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (delta != 0) return -1;
        } else return -1;
    }

    usz base = 1;
    while (base < item_count) base *= 2;
    long[2 * MAX_ITEMS] tree;
    long[2 * MAX_ITEMS] lazy;
    for (usz i = 0; i < 2 * base; i++) { tree[i] = 0; lazy[i] = 0; }
    for (usz i = 0; i < item_count; i++) tree[base + i] = values[i + 1];
    for (usz node = base; node > 1;) {
        node--;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz position = item_count + 2 + 4 * operation;
        usz left = (usz)values[position + 1], right = (usz)values[position + 2];
        if (values[position] == 0)
            range_add(&tree[0], &lazy[0], 1, 0, base, left, right, values[position + 3]);
        else
            checksum += range_sum(&tree[0], &lazy[0], 1, 0, base, left, right) + QUERY_OFFSET;
    }
    return checksum;
}
