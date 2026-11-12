const max_n: usize = 64;
const max_q: usize = 64;
const max_input_values: usize = 2 + 4 * max_q;

fn findRoot(parent: *[max_n]usize, item: usize) usize {
    var current = item;
    while (parent[current] != current) current = parent[current];
    return current;
}

fn visitVersion(node: usize, kind: *[max_q]i64, u: *[max_q]i64, v: *[max_q]i64,
    first_child: *[max_q + 1]i64, next_sibling: *[max_q]i64,
    parent: *[max_n]usize, set_size: *[max_n]usize,
    answer: *[max_q + 1]i64, history_child: *[max_q]i64,
    history_root: *[max_q]i64, history_size: *[max_q]i64,
    history_count: *usize) void {
    const saved_history = history_count.*;
    if (node != 0) {
        const operation = node - 1;
        if (kind[operation] == 0) {
            var root_u = findRoot(parent, @intCast(u[operation]));
            var root_v = findRoot(parent, @intCast(v[operation]));
            if (root_u == root_v) {
                history_child[history_count.*] = -1;
                history_root[history_count.*] = -1;
                history_size[history_count.*] = 0;
            } else {
                if (set_size[root_u] > set_size[root_v]) {
                    const temporary = root_u;
                    root_u = root_v;
                    root_v = temporary;
                }
                history_child[history_count.*] = @intCast(root_u);
                history_root[history_count.*] = @intCast(root_v);
                history_size[history_count.*] = @intCast(set_size[root_v]);
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
            }
            history_count.* += 1;
        } else {
            answer[node] = if (findRoot(parent, @intCast(u[operation])) ==
                findRoot(parent, @intCast(v[operation]))) 1 else 0;
        }
    }
    var child = first_child[node];
    while (child >= 0) {
        visitVersion(@intCast(child), kind, u, v, first_child, next_sibling, parent,
            set_size, answer, history_child, history_root, history_size, history_count);
        child = next_sibling[@as(usize, @intCast(child)) - 1];
    }
    while (history_count.* > saved_history) {
        history_count.* -= 1;
        const changed_child = history_child[history_count.*];
        if (changed_child >= 0) {
            const root: usize = @intCast(history_root[history_count.*]);
            parent[@intCast(changed_child)] = @intCast(changed_child);
            set_size[root] = @intCast(history_size[history_count.*]);
        }
    }
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn persistent_unionfind(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > 64 or q_value < 1 or q_value > 64) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + 4 * q) return -1;

    var kind: [max_q]i64 = undefined;
    var u: [max_q]i64 = undefined;
    var v: [max_q]i64 = undefined;
    var first_child: [max_q + 1]i64 = undefined;
    var next_sibling: [max_q]i64 = undefined;
    var answer: [max_q + 1]i64 = undefined;
    for (0..q + 1) |node| {
        first_child[node] = -1;
        answer[node] = 0;
    }
    var query_count: usize = 0;
    for (0..q) |operation| {
        const offset = 2 + 4 * operation;
        kind[operation] = input[offset];
        const version = input[offset + 1];
        u[operation] = input[offset + 2];
        v[operation] = input[offset + 3];
        if ((kind[operation] != 0 and kind[operation] != 1) or version < -1 or
            version >= @as(i64, @intCast(operation)) or u[operation] < 0 or
            u[operation] >= n_value or v[operation] < 0 or v[operation] >= n_value) return -1;
        if (version >= 0 and kind[@intCast(version)] != 0) return -1;
        if (kind[operation] == 1) query_count += 1;
        const parent_node: usize = @intCast(version + 1);
        next_sibling[operation] = first_child[parent_node];
        first_child[parent_node] = @intCast(operation + 1);
    }

    const required = 8 * query_count;
    if (output_opt == null or capacity < required) return -2;
    var parent: [max_n]usize = undefined;
    var set_size: [max_n]usize = undefined;
    for (0..n) |item| {
        parent[item] = item;
        set_size[item] = 1;
    }
    var history_child: [max_q]i64 = undefined;
    var history_root: [max_q]i64 = undefined;
    var history_size: [max_q]i64 = undefined;
    var history_count: usize = 0;
    visitVersion(0, &kind, &u, &v, &first_child, &next_sibling,
        &parent, &set_size, &answer, &history_child, &history_root,
        &history_size, &history_count);
    const output = output_opt.?;
    var written: usize = 0;
    for (0..q) |operation| {
        if (kind[operation] == 1) {
            storeI64Le(output, written, answer[operation + 1]);
            written += 8;
        }
    }
    return @intCast(written);
}
