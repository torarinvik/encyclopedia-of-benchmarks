const max_n: usize = 64;
const max_q: usize = 64;
const max_input: usize = 323;
const base: usize = 128;
const tree_size: usize = 256;

const Segment = struct {
    balance: i64 = 0,
    prefix_min: i64 = 0,
    suffix_max: i64 = 0,
    min_insert: i64 = 0,
    max_delete: i64 = -1,
};

const RetroQueue = struct {
    types: [max_n + 1]i64 = [_]i64{2} ** (max_n + 1),
    values: [max_n + 1]i64 = [_]i64{-1} ** (max_n + 1),
    tree: [tree_size]Segment = [_]Segment{.{}} ** tree_size,
    live_count: i64 = 0,
    live_sum: i64 = 0,
};

fn choose_min(q: *const RetroQueue, a: i64, b: i64) i64 {
    if (a == 0) return b;
    if (b == 0) return a;
    const ai: usize = @intCast(a);
    const bi: usize = @intCast(b);
    if (q.values[ai] != q.values[bi]) return if (q.values[ai] < q.values[bi]) a else b;
    return @max(a, b);
}

fn choose_max(q: *const RetroQueue, a: i64, b: i64) i64 {
    if (a == -1) return b;
    if (b == -1) return a;
    if (a == 0 or b == 0) return 0;
    const ai: usize = @intCast(a);
    const bi: usize = @intCast(b);
    if (q.values[ai] != q.values[bi]) return if (q.values[ai] > q.values[bi]) a else b;
    return @min(a, b);
}

fn pull(q: *RetroQueue, i: usize) void {
    var p = (base + i) / 2;
    while (p != 0) {
        const left = q.tree[2 * p];
        const right = q.tree[2 * p + 1];
        q.tree[p] = .{
            .balance = left.balance + right.balance,
            .prefix_min = @min(left.prefix_min, left.balance + right.prefix_min),
            .suffix_max = @max(left.suffix_max + right.balance, right.suffix_max),
            .min_insert = choose_min(q, left.min_insert, right.min_insert),
            .max_delete = choose_max(q, left.max_delete, right.max_delete),
        };
        p /= 2;
    }
}

fn next_bridge(q: *const RetroQueue, i: usize) usize {
    var left = base;
    var right = base + i + 1;
    var acc: i64 = 0;
    while (left < right) {
        if ((left & 1) == 1) { acc += q.tree[left].balance; left += 1; }
        if ((right & 1) == 1) { right -= 1; acc += q.tree[right].balance; }
        left /= 2;
        right /= 2;
    }
    if (acc == 0) return i + 1;
    var node = base + i + 1;
    while (true) {
        while ((node & 1) == 0) node /= 2;
        if (acc + q.tree[node].prefix_min == 0) {
            while (node < base) {
                node *= 2;
                if (acc + q.tree[node].prefix_min > 0) {
                    acc += q.tree[node].balance;
                    node += 1;
                }
            }
            return node - base;
        }
        acc += q.tree[node].balance;
        node += 1;
        if ((node & (~node + 1)) == node) return base;
    }
}

fn prev_bridge(q: *const RetroQueue, i: usize) usize {
    var left = base + i;
    var right = base * 2;
    var acc: i64 = 0;
    while (left < right) {
        if ((left & 1) == 1) { acc += q.tree[left].balance; left += 1; }
        if ((right & 1) == 1) { right -= 1; acc += q.tree[right].balance; }
        left /= 2;
        right /= 2;
    }
    if (acc == 0) return i;
    var node = base + i;
    while (true) {
        node -= 1;
        while (node > 1 and (node & 1) == 1) node /= 2;
        if (q.tree[node].suffix_max + acc == 0) {
            while (node < base) {
                node = 2 * node + 1;
                if (q.tree[node].suffix_max + acc < 0) {
                    acc += q.tree[node].balance;
                    node -= 1;
                }
            }
            return node - base;
        }
        acc += q.tree[node].balance;
        if ((node & (~node + 1)) == node) return 0;
    }
}

fn find_min_insert(q: *const RetroQueue, i: usize) i64 {
    var left = base;
    var right = base + next_bridge(q, i);
    var answer: i64 = 0;
    while (left < right) {
        if ((left & 1) == 1) { answer = choose_min(q, answer, q.tree[left].min_insert); left += 1; }
        if ((right & 1) == 1) { right -= 1; answer = choose_min(q, answer, q.tree[right].min_insert); }
        left /= 2;
        right /= 2;
    }
    return answer;
}

fn find_max_delete(q: *const RetroQueue, i: usize) i64 {
    var left = base + prev_bridge(q, i);
    var right = base * 2;
    var answer: i64 = -1;
    while (left < right) {
        if ((left & 1) == 1) { answer = choose_max(q, answer, q.tree[left].max_delete); left += 1; }
        if ((right & 1) == 1) { right -= 1; answer = choose_max(q, answer, q.tree[right].max_delete); }
        left /= 2;
        right /= 2;
    }
    return answer;
}

fn add_operation(q: *RetroQueue, i: usize) void {
    const k = find_max_delete(q, i);
    const leaf = base + i;
    if (choose_max(q, @intCast(i), k) == @as(i64, @intCast(i))) {
        q.live_sum += q.values[i];
        q.live_count += 1;
        q.tree[leaf].min_insert = @intCast(i);
        pull(q, i);
        return;
    }
    q.tree[leaf].max_delete = @intCast(i);
    q.tree[leaf].balance = 1;
    q.tree[leaf].suffix_max = 1;
    pull(q, i);
    const mate: usize = base + @as(usize, @intCast(k));
    if (k == 0) {
        q.tree[mate].balance -= 1;
        q.tree[mate].suffix_max -= 1;
        if (q.tree[mate].balance == 0) q.tree[mate].max_delete = -1;
    } else {
        const ki: usize = @intCast(k);
        q.live_sum += q.values[ki];
        q.live_count += 1;
        q.tree[mate].min_insert = k;
        q.tree[mate].max_delete = -1;
        q.tree[mate].balance = 0;
        q.tree[mate].suffix_max = 0;
    }
    pull(q, mate - base);
}

fn remove_insert(q: *RetroQueue, i: usize) void {
    const leaf = base + i;
    if (q.tree[leaf].balance == 0) {
        q.live_sum -= q.values[i];
        q.live_count -= 1;
        q.tree[leaf].min_insert = 0;
        pull(q, i);
        return;
    }
    const k = find_min_insert(q, i);
    q.tree[leaf].max_delete = -1;
    q.tree[leaf].balance = 0;
    q.tree[leaf].suffix_max = 0;
    pull(q, i);
    const ki: usize = @intCast(k);
    const mate = base + ki;
    if (k > 0) {
        q.live_sum -= q.values[ki];
        q.live_count -= 1;
    }
    q.tree[mate].min_insert = 0;
    q.tree[mate].max_delete = k;
    q.tree[mate].balance += 1;
    q.tree[mate].suffix_max += 1;
    pull(q, ki);
}

fn remove_minimum(q: *RetroQueue, i: usize) void {
    const k = find_min_insert(q, i);
    const leaf = base + i;
    q.tree[leaf].balance = -1;
    q.tree[leaf].prefix_min = -1;
    pull(q, i);
    if (k > 0) {
        const ki: usize = @intCast(k);
        q.live_sum -= q.values[ki];
        q.live_count -= 1;
    }
    const ki: usize = @intCast(k);
    const mate = base + ki;
    q.tree[mate].min_insert = 0;
    q.tree[mate].max_delete = k;
    q.tree[mate].balance += 1;
    q.tree[mate].suffix_max += 1;
    pull(q, ki);
}

fn restore_minimum(q: *RetroQueue, i: usize) void {
    const k = find_max_delete(q, i);
    const leaf = base + i;
    q.tree[leaf].balance = 0;
    q.tree[leaf].prefix_min = 0;
    pull(q, i);
    const ki: usize = @intCast(k);
    const mate = base + ki;
    if (k == 0) {
        q.tree[mate].balance -= 1;
        q.tree[mate].suffix_max -= 1;
        if (q.tree[mate].balance == 0) q.tree[mate].max_delete = -1;
    } else {
        q.live_sum += q.values[ki];
        q.live_count += 1;
        q.tree[mate].min_insert = k;
        q.tree[mate].max_delete = -1;
        q.tree[mate].balance = 0;
        q.tree[mate].suffix_max = 0;
    }
    pull(q, ki);
}

fn set_operation(q: *RetroQueue, index: usize, kind: i64, value: i64) void {
    const i = index + 1;
    if (q.types[i] == 0) remove_insert(q, i) else if (q.types[i] == 1) restore_minimum(q, i);
    q.types[i] = kind;
    q.values[i] = value;
    if (kind == 0) add_operation(q, i) else if (kind == 1) remove_minimum(q, i);
}

fn store_i64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

export fn partially_retroactive_priority_queue(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > max_input) return -1;
    const packed = input.?;
    if (packed[0] < 1 or packed[0] > @as(i64, @intCast(max_n)) or
        packed[1] < 1 or packed[1] > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(packed[0]);
    const qn: usize = @intCast(packed[1]);
    if (input_length != 2 + 2 * n + 3 * qn) return -1;
    var at: usize = 2;
    for (0..n) |_| {
        const kind = packed[at];
        const value = packed[at + 1];
        at += 2;
        if (kind == 0) {
            if (value < 0 or value > 1_000_000) return -1;
        } else if (!((kind == 1 or kind == 2) and value == -1)) return -1;
    }
    for (0..qn) |_| {
        const index = packed[at];
        const kind = packed[at + 1];
        const value = packed[at + 2];
        at += 3;
        if (index < 0 or index >= packed[0]) return -1;
        if (kind == 0) {
            if (value < 0 or value > 1_000_000) return -1;
        } else if (!((kind == 1 or kind == 2) and value == -1)) return -1;
    }
    const output_size = 16 * qn;
    if (output == null or capacity < output_size) return -2;
    var queue = RetroQueue{};
    at = 2;
    for (0..n) |i| {
        const kind = packed[at];
        const value = packed[at + 1];
        at += 2;
        set_operation(&queue, i, kind, value);
    }
    const result = output.?;
    var written: usize = 0;
    for (0..qn) |_| {
        const index: usize = @intCast(packed[at]);
        const kind = packed[at + 1];
        const value = packed[at + 2];
        at += 3;
        set_operation(&queue, index, kind, value);
        store_i64(result, written, queue.live_count);
        store_i64(result, written + 8, queue.live_sum);
        written += 16;
    }
    return @intCast(written);
}
