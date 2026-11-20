const std = @import("std");

const max_vertices: usize = 16;
const max_events: usize = 64;
const max_input_values: usize = 2 + 4 * max_events + 1;
const tree_nodes: usize = 4 * max_events + 8;

fn addInterval(node: usize, left: usize, right: usize,
    query_left: usize, query_right: usize, edge_id: usize,
    bucket_count: *[tree_nodes]usize,
    buckets: *[tree_nodes * max_events]usize) void {
    if (query_left <= left and right <= query_right) {
        buckets[node * max_events + bucket_count[node]] = edge_id;
        bucket_count[node] += 1;
        return;
    }
    const middle = left + (right - left) / 2;
    if (query_left < middle)
        addInterval(2 * node, left, middle, query_left, query_right, edge_id,
                    bucket_count, buckets);
    if (query_right > middle)
        addInterval(2 * node + 1, middle, right, query_left, query_right, edge_id,
                    bucket_count, buckets);
}

fn constrainOpposite(left: usize, right: usize,
    parent: *[max_vertices]usize, set_size: *[max_vertices]usize,
    xor_parent: *[max_vertices]usize,
    history_kind: *[max_events]usize, history_child: *[max_events]usize,
    history_root: *[max_events]usize, history_size: *[max_events]usize,
    history_xor: *[max_events]usize, history_count: *usize,
    contradictions: *usize) void {
    var root_left = left;
    var root_right = right;
    var parity_left: usize = 0;
    var parity_right: usize = 0;
    while (parent[root_left] != root_left) {
        parity_left ^= xor_parent[root_left];
        root_left = parent[root_left];
    }
    while (parent[root_right] != root_right) {
        parity_right ^= xor_parent[root_right];
        root_right = parent[root_right];
    }
    if (root_left == root_right) {
        if ((parity_left ^ parity_right) != 1) {
            history_kind[history_count.*] = 1;
            history_count.* += 1;
            contradictions.* += 1;
        }
        return;
    }
    if (set_size[root_left] > set_size[root_right]) {
        std.mem.swap(usize, &root_left, &root_right);
    }
    history_kind[history_count.*] = 0;
    history_child[history_count.*] = root_left;
    history_root[history_count.*] = root_right;
    history_size[history_count.*] = set_size[root_right];
    history_xor[history_count.*] = xor_parent[root_left];
    history_count.* += 1;
    parent[root_left] = root_right;
    xor_parent[root_left] = parity_left ^ parity_right ^ 1;
    set_size[root_right] += set_size[root_left];
}

fn rollbackTo(checkpoint: usize, parent: *[max_vertices]usize,
    set_size: *[max_vertices]usize, xor_parent: *[max_vertices]usize,
    history_kind: *const [max_events]usize,
    history_child: *const [max_events]usize,
    history_root: *const [max_events]usize,
    history_size: *const [max_events]usize,
    history_xor: *const [max_events]usize, history_count: *usize,
    contradictions: *usize) void {
    while (history_count.* > checkpoint) {
        history_count.* -= 1;
        const entry = history_count.*;
        if (history_kind[entry] == 1) {
            contradictions.* -= 1;
        } else {
            const child = history_child[entry];
            const root = history_root[entry];
            parent[child] = child;
            xor_parent[child] = history_xor[entry];
            set_size[root] = history_size[entry];
        }
    }
}

fn solveTimeTree(node: usize, left: usize, right: usize,
    operation: *const [max_events]i64,
    edge_left: *const [max_events]i64, edge_right: *const [max_events]i64,
    bucket_count: *const [tree_nodes]usize,
    buckets: *const [tree_nodes * max_events]usize,
    parent: *[max_vertices]usize, set_size: *[max_vertices]usize,
    xor_parent: *[max_vertices]usize,
    history_kind: *[max_events]usize, history_child: *[max_events]usize,
    history_root: *[max_events]usize, history_size: *[max_events]usize,
    history_xor: *[max_events]usize, history_count: *usize,
    contradictions: *usize, answer: *[max_events]i64) void {
    const checkpoint = history_count.*;
    for (0..bucket_count[node]) |entry| {
        const edge_id = buckets[node * max_events + entry];
        constrainOpposite(@intCast(edge_left[edge_id]), @intCast(edge_right[edge_id]),
            parent, set_size, xor_parent, history_kind, history_child,
            history_root, history_size, history_xor, history_count, contradictions);
    }
    if (right - left == 1) {
        if (operation[left] == 2)
            answer[left] = if (contradictions.* == 0) 1 else 0;
    } else {
        const middle = left + (right - left) / 2;
        solveTimeTree(2 * node, left, middle, operation, edge_left, edge_right,
            bucket_count, buckets, parent, set_size, xor_parent, history_kind,
            history_child, history_root, history_size, history_xor, history_count,
            contradictions, answer);
        solveTimeTree(2 * node + 1, middle, right, operation, edge_left, edge_right,
            bucket_count, buckets, parent, set_size, xor_parent, history_kind,
            history_child, history_root, history_size, history_xor, history_count,
            contradictions, answer);
    }
    rollbackTo(checkpoint, parent, set_size, xor_parent, history_kind,
        history_child, history_root, history_size, history_xor, history_count,
        contradictions);
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn offline_dynamic_bipartiteness(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_vertices)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(max_events))) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const event_count: usize = @intCast(input[1]);
    if (length != 2 + 4 * event_count) return -1;

    var operation = [_]i64{0} ** max_events;
    var first = [_]i64{0} ** max_events;
    var second = [_]i64{0} ** max_events;
    var edge_left = [_]i64{0} ** max_events;
    var edge_right = [_]i64{0} ** max_events;
    var start_time = [_]usize{0} ** max_events;
    var used_id = [_]bool{false} ** max_events;
    var active = [_]bool{false} ** max_events;
    var query_count: usize = 0;
    for (0..event_count) |time| {
        const offset = 2 + 4 * time;
        operation[time] = input[offset];
        first[time] = input[offset + 1];
        second[time] = input[offset + 2];
        const third = input[offset + 3];
        if (operation[time] == 0) {
            const edge_id = first[time];
            if (edge_id < 0 or edge_id >= @as(i64, @intCast(max_events)) or
                second[time] < 0 or second[time] > third or
                third >= @as(i64, @intCast(vertex_count)) or used_id[@intCast(edge_id)]) return -1;
            for (0..max_events) |prior| {
                if (active[prior] and edge_left[prior] == second[time] and edge_right[prior] == third)
                    return -1;
            }
            const id: usize = @intCast(edge_id);
            used_id[id] = true;
            active[id] = true;
            start_time[id] = time;
            edge_left[id] = second[time];
            edge_right[id] = third;
        } else if (operation[time] == 1) {
            const edge_id = first[time];
            if (edge_id < 0 or edge_id >= @as(i64, @intCast(max_events)) or
                !active[@intCast(edge_id)] or second[time] != 0 or third != 0) return -1;
            active[@intCast(edge_id)] = false;
        } else if (operation[time] == 2) {
            if (first[time] != 0 or second[time] != 0 or third != 0) return -1;
            query_count += 1;
        } else return -1;
    }

    const required = 8 * query_count;
    if (output_opt == null or capacity < required) return -2;
    var bucket_count = [_]usize{0} ** tree_nodes;
    var buckets = [_]usize{0} ** (tree_nodes * max_events);
    for (0..max_events) |edge_id| {
        if (!used_id[edge_id]) continue;
        var end_time = event_count;
        if (!active[edge_id]) {
            var time = start_time[edge_id] + 1;
            while (time < event_count) : (time += 1) {
                if (operation[time] == 1 and first[time] == @as(i64, @intCast(edge_id))) {
                    end_time = time;
                    break;
                }
            }
        }
        if (start_time[edge_id] < end_time and event_count != 0)
            addInterval(1, 0, event_count, start_time[edge_id], end_time, edge_id,
                        &bucket_count, &buckets);
    }

    var parent = [_]usize{0} ** max_vertices;
    var set_size = [_]usize{0} ** max_vertices;
    var xor_parent = [_]usize{0} ** max_vertices;
    for (0..vertex_count) |vertex| {
        parent[vertex] = vertex;
        set_size[vertex] = 1;
    }
    var history_kind = [_]usize{0} ** max_events;
    var history_child = [_]usize{0} ** max_events;
    var history_root = [_]usize{0} ** max_events;
    var history_size = [_]usize{0} ** max_events;
    var history_xor = [_]usize{0} ** max_events;
    var history_count: usize = 0;
    var contradictions: usize = 0;
    var answer = [_]i64{0} ** max_events;
    if (event_count != 0)
        solveTimeTree(1, 0, event_count, &operation, &edge_left, &edge_right,
            &bucket_count, &buckets, &parent, &set_size, &xor_parent,
            &history_kind, &history_child, &history_root, &history_size,
            &history_xor, &history_count, &contradictions, &answer);

    const output = output_opt.?;
    var written: usize = 0;
    for (0..event_count) |time| {
        if (operation[time] == 2) {
            storeI64Le(output, written, answer[time]);
            written += 8;
        }
    }
    return @intCast(written);
}
