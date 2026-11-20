const MAX_OPS: usize = 48;
const HANDLES: usize = 8;

fn normalize(start: i32, kinds: *const [MAX_OPS]u8, live: *const [MAX_OPS]bool,
    nexts: *const [MAX_OPS]i32) i32 {
    var head = start;
    while (head >= 0 and kinds.*[@intCast(head)] == 1 and !live.*[@intCast(head)]) {
        head = nexts.*[@intCast(head)];
    }
    return head;
}

fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn cactus_stack_branch_trace(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 146) return -1;
    const q_word = input[0];
    if (q_word < 0 or q_word > 48) return -1;
    const q: usize = @intCast(q_word);
    if (length != 1 + 3 * q) return -1;
    for (0..q) |i| {
        const op = input[1 + 3*i];
        const a = input[2 + 3*i];
        const b = input[3 + 3*i];
        if (op == 0) {
            if (a < 0 or a >= 8 or b < -1000 or b > 1000) return -1;
        } else if (op >= 1 and op <= 3) {
            if (a < 0 or a >= 8 or b != 0) return -1;
        } else if (op == 4) {
            if (a < 0 or a >= 8 or b < 0 or b >= 8) return -1;
        } else return -1;
    }

    var node_value = [_]i64{0} ** MAX_OPS;
    var node_next = [_]i32{-1} ** MAX_OPS;
    var node_kind = [_]u8{0} ** MAX_OPS;
    var node_live = [_]bool{false} ** MAX_OPS;
    var heads = [_]i32{-1} ** HANDLES;
    var branch_child = [_]i32{-1} ** HANDLES;
    var attached_owner = [_]i32{-1} ** HANDLES;
    var wrapper_for_child = [_]i32{-1} ** HANDLES;
    var statuses = [_]i64{0} ** MAX_OPS;
    var results = [_]i64{0} ** MAX_OPS;
    var node_count: usize = 0;

    for (0..q) |i| {
        const op = input[1 + 3*i];
        const a: usize = @intCast(input[2 + 3*i]);
        const b = input[3 + 3*i];
        heads[a] = normalize(heads[a], &node_kind, &node_live, &node_next);
        const head = heads[a];
        statuses[i] = 1;
        if (op == 0) {
            node_value[node_count] = b;
            node_next[node_count] = head;
            node_kind[node_count] = 0;
            node_live[node_count] = false;
            heads[a] = @intCast(node_count);
            node_count += 1;
        } else if (op == 1) {
            if (head < 0 or (node_kind[@intCast(head)] == 1 and node_live[@intCast(head)])) {
                statuses[i] = 0;
            } else {
                results[i] = node_value[@intCast(head)];
                heads[a] = normalize(node_next[@intCast(head)], &node_kind, &node_live, &node_next);
                if (heads[a] < 0 and attached_owner[a] >= 0) {
                    const owner: usize = @intCast(attached_owner[a]);
                    node_live[@intCast(wrapper_for_child[a])] = false;
                    branch_child[owner] = -1;
                    attached_owner[a] = -1;
                    wrapper_for_child[a] = -1;
                }
            }
        } else if (op == 2) {
            var top = head;
            while (top >= 0 and node_kind[@intCast(top)] == 1) {
                top = normalize(node_next[@intCast(top)], &node_kind, &node_live, &node_next);
            }
            if (top < 0) statuses[i] = 0 else results[i] = node_value[@intCast(top)];
        } else if (op == 3) {
            if (head >= 0 and node_kind[@intCast(head)] == 1 and node_live[@intCast(head)]) results[i] = 1;
        } else {
            const child: usize = @intCast(b);
            heads[child] = normalize(heads[child], &node_kind, &node_live, &node_next);
            var owner_top = head;
            while (owner_top >= 0 and node_kind[@intCast(owner_top)] == 1) {
                owner_top = normalize(node_next[@intCast(owner_top)], &node_kind, &node_live, &node_next);
            }
            if (a == child or owner_top < 0 or attached_owner[a] >= 0 or branch_child[a] >= 0
                or attached_owner[child] >= 0 or branch_child[child] >= 0) return -1;
            if (heads[child] < 0) {
                results[i] = 0;
            } else {
                node_value[node_count] = 0;
                node_next[node_count] = head;
                node_kind[node_count] = 1;
                node_live[node_count] = true;
                const wrapper: i32 = @intCast(node_count);
                node_count += 1;
                heads[a] = wrapper;
                branch_child[a] = @intCast(child);
                attached_owner[child] = @intCast(a);
                wrapper_for_child[child] = wrapper;
                results[i] = 1;
            }
        }
    }

    const required = 16 * q;
    if (output == null or capacity < required) return -2;
    for (0..q) |i| {
        storeLe(output, 16*i, statuses[i]);
        storeLe(output, 16*i+8, results[i]);
    }
    return @intCast(required);
}
