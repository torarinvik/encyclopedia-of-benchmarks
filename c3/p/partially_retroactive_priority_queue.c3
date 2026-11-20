module partially_retroactive_priority_queue;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_INPUT = 323;
const usz BASE = 128;
const usz TREE_SIZE = 256;

struct Segment { int balance; int prefix_min; int suffix_max; int min_insert; int max_delete; }
struct RetroQueue {
    int[65] types;
    long[65] values;
    Segment[256] tree;
    long live_count;
    long live_sum;
}

fn int pick_min_insert(RetroQueue* q, int a, int b) {
    if (a == 0) return b;
    if (b == 0) return a;
    if (q.values[a] != q.values[b]) return q.values[a] < q.values[b] ? a : b;
    return a > b ? a : b;
}

fn int pick_max_delete(RetroQueue* q, int a, int b) {
    if (a == -1) return b;
    if (b == -1) return a;
    if (a == 0 || b == 0) return 0;
    if (q.values[a] != q.values[b]) return q.values[a] > q.values[b] ? a : b;
    return a < b ? a : b;
}

fn void pull(RetroQueue* q, usz i) {
    usz p = (BASE + i) >> 1;
    while (p != 0) {
        Segment* node = &q.tree[p];
        Segment* left = &q.tree[p * 2];
        Segment* right = &q.tree[p * 2 + 1];
        node.balance = left.balance + right.balance;
        int through_left = left.balance + right.prefix_min;
        node.prefix_min = left.prefix_min < through_left ? left.prefix_min : through_left;
        int through_right = left.suffix_max + right.balance;
        node.suffix_max = through_right > right.suffix_max ? through_right : right.suffix_max;
        node.min_insert = pick_min_insert(q, left.min_insert, right.min_insert);
        node.max_delete = pick_max_delete(q, left.max_delete, right.max_delete);
        p >>= 1;
    }
}

fn usz next_bridge(RetroQueue* q, usz i) {
    usz left = BASE;
    usz right = BASE + i + 1;
    int acc = 0;
    while (left < right) {
        if (left & 1) { acc += q.tree[left].balance; left++; }
        if (right & 1) { right--; acc += q.tree[right].balance; }
        left >>= 1; right >>= 1;
    }
    if (acc == 0) return i + 1;
    usz node = BASE + i + 1;
    while (true) {
        while ((node & 1) == 0) node >>= 1;
        if (acc + q.tree[node].prefix_min == 0) {
            while (node < BASE) {
                node <<= 1;
                if (acc + q.tree[node].prefix_min > 0) { acc += q.tree[node].balance; node++; }
            }
            return node - BASE;
        }
        acc += q.tree[node].balance;
        node++;
        if ((node & (~node + 1)) == node) return BASE;
    }
    return BASE;
}

fn usz prev_bridge(RetroQueue* q, usz i) {
    usz left = BASE + i;
    usz right = BASE * 2;
    int acc = 0;
    while (left < right) {
        if (left & 1) { acc += q.tree[left].balance; left++; }
        if (right & 1) { right--; acc += q.tree[right].balance; }
        left >>= 1; right >>= 1;
    }
    if (acc == 0) return i;
    usz node = BASE + i;
    while (true) {
        node--;
        while (node > 1 && (node & 1)) node >>= 1;
        if (q.tree[node].suffix_max + acc == 0) {
            while (node < BASE) {
                node = (node << 1) | 1;
                if (q.tree[node].suffix_max + acc < 0) { acc += q.tree[node].balance; node--; }
            }
            return node - BASE;
        }
        acc += q.tree[node].balance;
        if ((node & (~node + 1)) == node) return 0;
    }
    return 0;
}

fn int find_min_insert(RetroQueue* q, usz i) {
    usz left = BASE, right = BASE + next_bridge(q, i);
    int answer = 0;
    while (left < right) {
        if (left & 1) { answer = pick_min_insert(q, answer, q.tree[left].min_insert); left++; }
        if (right & 1) { right--; answer = pick_min_insert(q, answer, q.tree[right].min_insert); }
        left >>= 1; right >>= 1;
    }
    return answer;
}

fn int find_max_delete(RetroQueue* q, usz i) {
    usz left = BASE + prev_bridge(q, i), right = BASE * 2;
    int answer = -1;
    while (left < right) {
        if (left & 1) { answer = pick_max_delete(q, answer, q.tree[left].max_delete); left++; }
        if (right & 1) { right--; answer = pick_max_delete(q, answer, q.tree[right].max_delete); }
        left >>= 1; right >>= 1;
    }
    return answer;
}

fn void add_operation(RetroQueue* q, usz i) {
    int k = find_max_delete(q, i);
    if (pick_max_delete(q, (int)i, k) == (int)i) {
        q.live_sum += q.values[i]; q.live_count++;
        q.tree[BASE + i].min_insert = (int)i; pull(q, i); return;
    }
    Segment* leaf = &q.tree[BASE + i];
    leaf.balance = 1; leaf.suffix_max = 1; leaf.max_delete = (int)i;
    pull(q, i);
    Segment* mate = &q.tree[BASE + (usz)k];
    if (k == 0) {
        mate.balance--; mate.suffix_max--;
        if (mate.balance == 0) mate.max_delete = -1;
    } else {
        q.live_sum += q.values[k]; q.live_count++;
        mate.min_insert = k; mate.max_delete = -1; mate.balance = 0; mate.suffix_max = 0;
    }
    pull(q, (usz)k);
}

fn void remove_insert(RetroQueue* q, usz i) {
    Segment* leaf = &q.tree[BASE + i];
    if (leaf.balance == 0) {
        q.live_sum -= q.values[i]; q.live_count--; leaf.min_insert = 0; pull(q, i); return;
    }
    int k = find_min_insert(q, i);
    leaf.max_delete = -1; leaf.balance = 0; leaf.suffix_max = 0; pull(q, i);
    Segment* mate = &q.tree[BASE + (usz)k];
    if (k > 0) { q.live_sum -= q.values[k]; q.live_count--; }
    mate.min_insert = 0; mate.max_delete = k; mate.balance++; mate.suffix_max++;
    pull(q, (usz)k);
}

fn void remove_minimum(RetroQueue* q, usz i) {
    int k = find_min_insert(q, i);
    Segment* leaf = &q.tree[BASE + i]; leaf.balance = -1; leaf.prefix_min = -1; pull(q, i);
    if (k > 0) { q.live_sum -= q.values[k]; q.live_count--; }
    Segment* mate = &q.tree[BASE + (usz)k];
    mate.min_insert = 0; mate.max_delete = k; mate.balance++; mate.suffix_max++;
    pull(q, (usz)k);
}

fn void restore_minimum(RetroQueue* q, usz i) {
    int k = find_max_delete(q, i);
    Segment* leaf = &q.tree[BASE + i]; leaf.balance = 0; leaf.prefix_min = 0; pull(q, i);
    Segment* mate = &q.tree[BASE + (usz)k];
    if (k == 0) {
        mate.balance--; mate.suffix_max--;
        if (mate.balance == 0) mate.max_delete = -1;
    } else {
        q.live_sum += q.values[k]; q.live_count++;
        mate.min_insert = k; mate.max_delete = -1; mate.balance = 0; mate.suffix_max = 0;
    }
    pull(q, (usz)k);
}

fn void set_operation(RetroQueue* q, usz index, int kind, long value) {
    usz i = index + 1;
    if (q.types[i] == 0) remove_insert(q, i);
    else if (q.types[i] == 1) restore_minimum(q, i);
    q.types[i] = kind; q.values[i] = value;
    if (kind == 0) add_operation(q, i);
    else if (kind == 1) remove_minimum(q, i);
}

fn void write_i64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { output[offset + b] = (uchar)(bits & 255); bits >>= 8; }
}

fn long partially_retroactive_priority_queue(long* input, usz length, uchar* output, usz capacity)
    @export("partially_retroactive_priority_queue") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_Q) return -1;
    usz n = (usz)input[0], qn = (usz)input[1];
    if (length != 2 + 2 * n + 3 * qn) return -1;
    usz at = 2;
    for (usz i = 0; i < n; i++) {
        long kind = input[at++], value = input[at++];
        if (kind == 0) { if (value < 0 || value > 1000000) return -1; }
        else if (!((kind == 1 || kind == 2) && value == -1)) return -1;
    }
    for (usz i = 0; i < qn; i++) {
        long index = input[at++], kind = input[at++], value = input[at++];
        if (index < 0 || index >= (long)n) return -1;
        if (kind == 0) { if (value < 0 || value > 1000000) return -1; }
        else if (!((kind == 1 || kind == 2) && value == -1)) return -1;
    }
    usz output_size = 16 * qn;
    if (output == null || capacity < output_size) return -2;
    RetroQueue queue;
    queue.live_count = 0; queue.live_sum = 0;
    for (usz i = 0; i <= n; i++) { queue.types[i] = 2; queue.values[i] = -1; }
    for (usz i = 0; i < TREE_SIZE; i++) queue.tree[i] = Segment{0, 0, 0, 0, -1};
    at = 2;
    for (usz i = 0; i < n; i++) { int kind = (int)input[at++]; long value = input[at++]; set_operation(&queue, i, kind, value); }
    usz written = 0;
    for (usz i = 0; i < qn; i++) {
        usz index = (usz)input[at++]; int kind = (int)input[at++]; long value = input[at++];
        set_operation(&queue, index, kind, value);
        write_i64(output, written, queue.live_count);
        write_i64(output, written + 8, queue.live_sum);
        written += 16;
    }
    return (long)written;
}
