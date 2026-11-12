module segment_history_extreme;

const usz SH_MAX_N = 32;
const usz SH_MAX_Q = 32;
const usz SH_MAX_INPUT = 2 + SH_MAX_N + 4 * SH_MAX_Q;
const usz SH_TREE_SIZE = 4 * SH_MAX_N;
const long SH_VALUE_LIMIT = 1000;

struct ShNode {
    long maximum;
    long history_maximum;
    long add;
    long add_peak;
    long set_value;
    long set_peak;
    bool has_set;
}

fn long sh_max(long a, long b) { return a > b ? a : b; }

fn void sh_apply_add_summary(ShNode* node, long net, long peak) {
    node.history_maximum = sh_max(node.history_maximum, node.maximum + peak);
    node.maximum += net;
    if (node.has_set) {
        node.set_peak = sh_max(node.set_peak, node.set_value + peak);
        node.set_value += net;
    } else {
        node.add_peak = sh_max(node.add_peak, node.add + peak);
        node.add += net;
    }
}

fn void sh_apply_add(ShNode* node, long delta) {
    if (node.has_set) {
        node.set_peak = sh_max(node.set_peak, node.set_value + delta);
        node.set_value += delta;
    } else {
        node.add_peak = sh_max(node.add_peak, node.add + delta);
        node.add += delta;
    }
    node.history_maximum = sh_max(node.history_maximum, node.maximum + delta);
    node.maximum += delta;
}

fn void sh_apply_set_summary(ShNode* node, long value, long peak) {
    node.history_maximum = sh_max(node.history_maximum, peak);
    node.maximum = value;
    if (node.has_set) node.set_peak = sh_max(node.set_peak, peak);
    else { node.has_set = true; node.set_peak = peak; }
    node.set_value = value;
}

fn void sh_apply_set(ShNode* node, long value) {
    node.history_maximum = sh_max(node.history_maximum, value);
    node.maximum = value;
    if (node.has_set) node.set_peak = sh_max(node.set_peak, value);
    else { node.has_set = true; node.set_peak = value; }
    node.set_value = value;
}

fn void sh_push(ShNode* tree, usz node) {
    ShNode* parent = &tree[node];
    if (parent.add != 0 || parent.add_peak != 0) {
        sh_apply_add_summary(&tree[2 * node], parent.add, parent.add_peak);
        sh_apply_add_summary(&tree[2 * node + 1], parent.add, parent.add_peak);
        parent.add = 0;
        parent.add_peak = 0;
    }
    if (parent.has_set) {
        sh_apply_set_summary(&tree[2 * node], parent.set_value, parent.set_peak);
        sh_apply_set_summary(&tree[2 * node + 1], parent.set_value, parent.set_peak);
        parent.has_set = false;
        parent.set_value = 0;
        parent.set_peak = 0;
    }
}

fn void sh_pull(ShNode* tree, usz node) {
    tree[node].maximum = sh_max(tree[2 * node].maximum, tree[2 * node + 1].maximum);
    tree[node].history_maximum = sh_max(tree[2 * node].history_maximum, tree[2 * node + 1].history_maximum);
}

fn void sh_build(ShNode* tree, long* values, usz node, usz left, usz right) {
    if (right - left == 1) {
        tree[node].maximum = values[left];
        tree[node].history_maximum = values[left];
        return;
    }
    usz middle = left + (right - left) / 2;
    sh_build(tree, values, 2 * node, left, middle);
    sh_build(tree, values, 2 * node + 1, middle, right);
    sh_pull(tree, node);
}

fn void sh_update(ShNode* tree, usz node, usz left, usz right, usz ql, usz qr,
                  bool assignment, long value) {
    if (ql <= left && right <= qr) {
        if (assignment) sh_apply_set(&tree[node], value);
        else sh_apply_add(&tree[node], value);
        return;
    }
    sh_push(tree, node);
    usz middle = left + (right - left) / 2;
    if (ql < middle) sh_update(tree, 2 * node, left, middle, ql, qr, assignment, value);
    if (middle < qr) sh_update(tree, 2 * node + 1, middle, right, ql, qr, assignment, value);
    sh_pull(tree, node);
}

fn long sh_query(ShNode* tree, usz node, usz left, usz right,
                 usz ql, usz qr, bool historical) {
    if (ql <= left && right <= qr)
        return historical ? tree[node].history_maximum : tree[node].maximum;
    sh_push(tree, node);
    usz middle = left + (right - left) / 2;
    long answer = -1000000000000L;
    if (ql < middle) answer = sh_query(tree, 2 * node, left, middle, ql, qr, historical);
    if (middle < qr) answer = sh_max(answer, sh_query(tree, 2 * node + 1, middle, right, ql, qr, historical));
    return answer;
}

fn void sh_write_i64(u8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (u8)(bits >> (8 * byte));
}

fn long segment_history_extreme(long* input, usz input_length, u8* output, usz output_capacity)
    @export("segment_history_extreme") {
    if (input == null || input_length < 2 || input_length > SH_MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)SH_MAX_N || q_value < 0 || q_value > (long)SH_MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (input_length != 2 + n + 4 * q) return -1;
    usz operation_offset = 2 + n;
    for (usz i = 0; i < n; i++)
        if (input[2 + i] < -SH_VALUE_LIMIT || input[2 + i] > SH_VALUE_LIMIT) return -1;
    for (usz i = 0; i < q; i++) {
        long* record = input + operation_offset + 4 * i;
        long op = record[0], left = record[1], right = record[2], arg = record[3];
        if (op < 0 || op > 3 || left < 0 || right <= left || right > n_value) return -1;
        if (op < 2) {
            if (arg < -SH_VALUE_LIMIT || arg > SH_VALUE_LIMIT) return -1;
        } else if (arg != 0) return -1;
    }

    ShNode[SH_TREE_SIZE] tree = zeroed;
    long[SH_MAX_Q] staged = zeroed;
    usz answer_count = 0;
    sh_build(&tree[0], input + 2, 1, 0, n);
    for (usz i = 0; i < q; i++) {
        long* record = input + operation_offset + 4 * i;
        int op = (int)record[0];
        usz left = (usz)record[1], right = (usz)record[2];
        if (op < 2) sh_update(&tree[0], 1, 0, n, left, right, op == 0, record[3]);
        else staged[answer_count++] = sh_query(&tree[0], 1, 0, n, left, right, op == 3);
    }
    usz output_bytes = 8 * answer_count;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < answer_count; i++) sh_write_i64(output, 8 * i, staged[i]);
    return (long)output_bytes;
}
