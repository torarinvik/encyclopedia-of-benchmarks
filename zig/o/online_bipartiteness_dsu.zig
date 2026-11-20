const std = @import("std");

const max_n: usize = 32;
const max_q: usize = 64;
const max_input_values: usize = 195;

const FindResult = struct { root: usize, xor_to_root: i64 };

fn findParity(parent: *[max_n]usize, parity: *[max_n]i64, start: usize) FindResult {
    var root = start;
    var total: i64 = 0;
    while (parent[root] != root) {
        total ^= parity[root];
        root = parent[root];
    }
    var node = start;
    var accumulated: i64 = 0;
    while (parent[node] != node) {
        const next = parent[node];
        const edge = parity[node];
        parent[node] = root;
        parity[node] = total ^ accumulated;
        accumulated ^= edge;
        node = next;
    }
    return .{ .root = root, .xor_to_root = total };
}

export fn online_bipartiteness_dsu(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n)) or input[1] < 0 or input[1] > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + 3 * q) return -1;
    for (0..q) |j| {
        const opcode = input[2 + 3 * j];
        const a = input[3 + 3 * j];
        const b = input[4 + 3 * j];
        if (opcode == 0) {
            if (a < 0 or a >= @as(i64, @intCast(n)) or b < 0 or b >= @as(i64, @intCast(n))) return -1;
        } else if (opcode == 1) {
            if (a < 0 or a >= @as(i64, @intCast(n)) or b != 0) return -1;
        } else return -1;
    }
    var parent = [_]usize{0} ** max_n;
    var size = [_]usize{0} ** max_n;
    var parity = [_]i64{0} ** max_n;
    var bad = [_]bool{false} ** max_n;
    for (0..n) |i| { parent[i] = i; size[i] = 1; }
    var checksum: i64 = 0;
    var query_ordinal: i64 = 0;
    for (0..q) |j| {
        const opcode = input[2 + 3 * j];
        const a: usize = @intCast(input[3 + 3 * j]);
        if (opcode == 1) {
            const found = findParity(&parent, &parity, a);
            const answer: i64 = if (bad[found.root]) 0 else 1;
            checksum += (query_ordinal + 1) * (answer + 1);
            query_ordinal += 1;
            continue;
        }
        const b: usize = @intCast(input[4 + 3 * j]);
        var found_a = findParity(&parent, &parity, a);
        var found_b = findParity(&parent, &parity, b);
        if (found_a.root == found_b.root) {
            if (found_a.xor_to_root == found_b.xor_to_root) bad[found_a.root] = true;
            continue;
        }
        if (size[found_a.root] < size[found_b.root]) std.mem.swap(FindResult, &found_a, &found_b);
        parent[found_b.root] = found_a.root;
        parity[found_b.root] = found_a.xor_to_root ^ found_b.xor_to_root ^ 1;
        size[found_a.root] += size[found_b.root];
        bad[found_a.root] = bad[found_a.root] or bad[found_b.root];
    }
    return checksum;
}
