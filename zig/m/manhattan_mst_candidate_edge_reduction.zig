const std = @import("std");

const MAX_N: usize = 31;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;
const MAX_CANDIDATE_EDGES: usize = 4 * MAX_N;
const COORDINATE_BITSET_WORDS: usize = 32;
const COORDINATE_LIMIT: i64 = 1_000;

const Point = struct { x: i64 = 0, y: i64 = 0 };
const Edge = struct { weight: i64 = 0, u: usize = 0, v: usize = 0 };

fn markCoordinate(seen: *[COORDINATE_BITSET_WORDS]u64, coordinate: i64) bool {
    const index: usize = @intCast(coordinate + COORDINATE_LIMIT);
    const word = index / 64;
    const bit = @as(u64, 1) << @intCast(index % 64);
    if (seen[word] & bit != 0) return false;
    seen[word] |= bit;
    return true;
}

fn lessSum(left: usize, right: usize, points: *const [MAX_N]Point) bool {
    const left_sum = points[left].x + points[left].y;
    const right_sum = points[right].x + points[right].y;
    if (left_sum != right_sum) return left_sum < right_sum;
    if (points[left].x != points[right].x) return points[left].x < points[right].x;
    return left < right;
}

fn sortBySum(order: *[MAX_N]usize, count: usize, points: *const [MAX_N]Point) void {
    std.mem.sort(usize, order[0..count], points, struct {
        fn lessThan(context: *const [MAX_N]Point, left: usize, right: usize) bool {
            return lessSum(left, right, context);
        }
    }.lessThan);
}

fn sortByX(order: *[MAX_N]usize, count: usize, points: *const [MAX_N]Point) void {
    std.mem.sort(usize, order[0..count], points, struct {
        fn lessThan(context: *const [MAX_N]Point, left: usize, right: usize) bool {
            if (context[left].x != context[right].x) return context[left].x < context[right].x;
            return left < right;
        }
    }.lessThan);
}

fn fenwickAdd(tree: *[MAX_N + 1]i32, index_input: usize, delta: i32, count: usize) void {
    var index = index_input;
    while (index <= count) {
        tree[index] += delta;
        index += index & (~index + 1);
    }
}

fn fenwickPrefix(tree: *const [MAX_N + 1]i32, index_input: usize) usize {
    var index = index_input;
    var total: usize = 0;
    while (index > 0) {
        total += @intCast(tree[index]);
        index &= index - 1;
    }
    return total;
}

fn fenwickFindByOrder(tree: *const [MAX_N + 1]i32, count: usize, order: usize) usize {
    var step: usize = 1;
    while (step * 2 <= count) step *= 2;
    var index: usize = 0;
    var remaining = order;
    while (step > 0) {
        const next = index + step;
        if (next <= count and @as(usize, @intCast(tree[next])) < remaining) {
            index = next;
            remaining -= @intCast(tree[next]);
        }
        step /= 2;
    }
    return index;
}

fn lessEdge(left: Edge, right: Edge) bool {
    if (left.weight != right.weight) return left.weight < right.weight;
    if (left.u != right.u) return left.u < right.u;
    return left.v < right.v;
}

fn sortEdges(edges: *[MAX_CANDIDATE_EDGES]Edge, count: usize) void {
    std.mem.sort(Edge, edges[0..count], {}, struct {
        fn lessThan(_: void, left: Edge, right: Edge) bool {
            return lessEdge(left, right);
        }
    }.lessThan);
}

fn findRoot(parent: *[MAX_N]usize, node_input: usize) usize {
    var node = node_input;
    var root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

export fn manhattan_mst_candidate_edge_reduction(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_N))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;

    var points: [MAX_N]Point = @splat(.{});
    var seen_x: [COORDINATE_BITSET_WORDS]u64 = @splat(0);
    var seen_y: [COORDINATE_BITSET_WORDS]u64 = @splat(0);
    for (0..count) |point| {
        const x = input[1 + 2 * point];
        const y = input[2 + 2 * point];
        if (x < -COORDINATE_LIMIT or x > COORDINATE_LIMIT or
            y < -COORDINATE_LIMIT or y > COORDINATE_LIMIT) return -1;
        if (!markCoordinate(&seen_x, x) or !markCoordinate(&seen_y, y)) return -1;
        points[point] = .{ .x = x, .y = y };
    }
    if (count < 2) return 0;

    var edges: [MAX_CANDIDATE_EDGES]Edge = @splat(.{});
    var edge_count: usize = 0;
    for (0..4) |pass| {
        var sum_order: [MAX_N]usize = @splat(0);
        var x_order: [MAX_N]usize = @splat(0);
        for (0..count) |point| {
            sum_order[point] = point;
            x_order[point] = point;
        }
        sortBySum(&sum_order, count, &points);
        sortByX(&x_order, count, &points);
        var rank_of_id: [MAX_N]usize = @splat(0);
        var id_at_rank: [MAX_N]usize = @splat(0);
        for (0..count) |rank| {
            const point = x_order[rank];
            rank_of_id[point] = rank;
            id_at_rank[rank] = point;
        }

        var fenwick: [MAX_N + 1]i32 = @splat(0);
        for (0..count) |order_index| {
            const current = sum_order[order_index];
            const current_rank = rank_of_id[current];
            while (true) {
                const active_count = fenwickPrefix(&fenwick, current_rank + 1);
                if (active_count == 0) break;
                const candidate_rank = fenwickFindByOrder(&fenwick, count, active_count);
                const candidate = id_at_rank[candidate_rank];
                if (points[current].x - points[current].y >
                    points[candidate].x - points[candidate].y) break;
                if (edge_count >= MAX_CANDIDATE_EDGES) return -1;
                const u = @min(current, candidate);
                const v = @max(current, candidate);
                const dx = points[current].x - points[candidate].x;
                const dy = points[current].y - points[candidate].y;
                const weight = @abs(dx) + @abs(dy);
                edges[edge_count] = .{ .weight = weight, .u = u, .v = v };
                edge_count += 1;
                fenwickAdd(&fenwick, candidate_rank + 1, -1, count);
            }
            fenwickAdd(&fenwick, current_rank + 1, 1, count);
        }

        for (0..count) |point| {
            if (pass % 2 == 0) {
                const temporary = points[point].x;
                points[point].x = points[point].y;
                points[point].y = temporary;
            } else {
                points[point].x = -points[point].x;
            }
        }
    }

    sortEdges(&edges, edge_count);
    var parent: [MAX_N]usize = @splat(0);
    var size: [MAX_N]usize = @splat(1);
    for (0..count) |point| parent[point] = point;
    var total: i64 = 0;
    var accepted: usize = 0;
    for (0..edge_count) |edge_index| {
        const edge = edges[edge_index];
        const left = findRoot(&parent, edge.u);
        const right = findRoot(&parent, edge.v);
        if (left == right) continue;
        if (size[left] < size[right]) {
            parent[left] = right;
            size[right] += size[left];
        } else {
            parent[right] = left;
            size[left] += size[right];
        }
        total += edge.weight;
        accepted += 1;
        if (accepted + 1 == count) break;
    }
    if (accepted + 1 != count) return -1;
    return total;
}
