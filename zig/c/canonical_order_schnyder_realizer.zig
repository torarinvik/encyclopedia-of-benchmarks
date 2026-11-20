const std = @import("std");

const MAX_N: usize = 8;
const MAX_INPUT: usize = 49;
const MAX_DARTS: usize = 48;

const Embedding = struct {
    n: usize,
    u: usize,
    v: usize,
    w: usize,
    degree: [MAX_N]usize = [_]usize{0} ** MAX_N,
    rotation: [MAX_N][MAX_N]usize = [_][MAX_N]usize{[_]usize{0} ** MAX_N} ** MAX_N,
    adjacent: [MAX_N][MAX_N]bool = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N,
};

fn nextActive(g: *const Embedding, active: *const [MAX_N]bool, source: usize, target: usize) ?usize {
    var source_position: ?usize = null;
    var remaining: usize = 0;
    for (0..g.degree[target]) |index| {
        const neighbor = g.rotation[target][index];
        if (!active.*[neighbor]) continue;
        remaining += 1;
        if (neighbor == source) source_position = index;
    }
    if (remaining < 2 or source_position == null) return null;
    for (1..g.degree[target] + 1) |step| {
        const neighbor = g.rotation[target][(source_position.? + step) % g.degree[target]];
        if (active.*[neighbor]) return neighbor;
    }
    return null;
}

fn faceCycle(g: *const Embedding, active: *const [MAX_N]bool, first: usize, second: usize,
    cycle: *[MAX_DARTS]usize) ?usize {
    var seen = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var source = first;
    var target = second;
    var length: usize = 0;
    for (0..MAX_DARTS) |_| {
        if (source >= g.n or target >= g.n or !active.*[source] or !active.*[target] or
            !g.adjacent[source][target] or seen[source][target]) return null;
        seen[source][target] = true;
        cycle.*[length] = source;
        length += 1;
        const following = nextActive(g, active, source, target) orelse return null;
        source = target;
        target = following;
        if (source == first and target == second) return length;
    }
    return null;
}

fn parseEmbedding(values: []const i64) ?Embedding {
    if (values.len < 4 or values.len > MAX_INPUT) return null;
    if (values[0] < 3 or values[0] > MAX_N) return null;
    const n: usize = @intCast(values[0]);
    if (values[1] < 0 or values[2] < 0 or values[3] < 0 or values[1] >= values[0] or
        values[2] >= values[0] or values[3] >= values[0] or values[1] == values[2] or
        values[1] == values[3] or values[2] == values[3]) return null;
    var g = Embedding{ .n = n, .u = @intCast(values[1]), .v = @intCast(values[2]), .w = @intCast(values[3]) };
    var offset: usize = 4;
    var degree_sum: usize = 0;
    for (0..n) |vertex| {
        if (offset >= values.len or values[offset] < 2 or values[offset] >= values[0]) return null;
        const degree: usize = @intCast(values[offset]);
        offset += 1;
        if (offset + degree > values.len) return null;
        var row_seen = [_]bool{false} ** MAX_N;
        g.degree[vertex] = degree;
        degree_sum += degree;
        for (0..degree) |rank| {
            const raw = values[offset + rank];
            if (raw < 0 or raw >= values[0] or raw == @as(i64, @intCast(vertex))) return null;
            const neighbor: usize = @intCast(raw);
            if (row_seen[neighbor]) return null;
            row_seen[neighbor] = true;
            g.rotation[vertex][rank] = neighbor;
            g.adjacent[vertex][neighbor] = true;
        }
        offset += degree;
    }
    if (offset != values.len or degree_sum != 6 * n - 12) return null;
    var edge_count: usize = 0;
    for (0..n) |a| for (0..n) |b| {
        if (g.adjacent[a][b] != g.adjacent[b][a]) return null;
        if (a < b and g.adjacent[a][b]) edge_count += 1;
    };
    if (edge_count != 3 * n - 6) return null;
    var reached = [_]bool{false} ** MAX_N;
    var stack = [_]usize{0} ** MAX_N;
    var stack_size: usize = 1;
    var reached_count: usize = 0;
    reached[0] = true;
    while (stack_size > 0) {
        stack_size -= 1;
        const vertex = stack[stack_size];
        reached_count += 1;
        for (0..n) |neighbor| {
            if (g.adjacent[vertex][neighbor] and !reached[neighbor]) {
                reached[neighbor] = true;
                stack[stack_size] = neighbor;
                stack_size += 1;
            }
        }
    }
    if (reached_count != n) return null;
    var active = [_]bool{false} ** MAX_N;
    @memset(active[0..n], true);
    var seen_dart = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var face_count: usize = 0;
    var visited_darts: usize = 0;
    for (0..n) |source| for (0..n) |target| {
        if (!g.adjacent[source][target] or seen_dart[source][target]) continue;
        var cycle = [_]usize{0} ** MAX_DARTS;
        const face_length = faceCycle(&g, &active, source, target, &cycle) orelse return null;
        if (face_length != 3) return null;
        face_count += 1;
        for (0..face_length) |i| {
            const a = cycle[i];
            const b = cycle[(i + 1) % face_length];
            if (seen_dart[a][b]) return null;
            seen_dart[a][b] = true;
            visited_darts += 1;
        }
    };
    if (face_count != 2 * n - 4 or visited_darts != 6 * n - 12) return null;
    var outer = [_]usize{0} ** MAX_DARTS;
    const outer_len = faceCycle(&g, &active, g.u, g.v, &outer) orelse return null;
    if (outer_len != 3 or outer[0] != g.u or outer[1] != g.v or outer[2] != g.w) return null;
    return g;
}

fn boundaryPath(g: *const Embedding, active: *const [MAX_N]bool, path: *[MAX_N]usize) ?usize {
    var cycle = [_]usize{0} ** MAX_DARTS;
    const length = faceCycle(g, active, g.u, g.v, &cycle) orelse return null;
    if (length < 3) return null;
    var count: usize = 1;
    path.*[0] = g.u;
    var index = length;
    while (index > 2) {
        index -= 1;
        path.*[count] = cycle[index];
        count += 1;
    }
    path.*[count] = g.v;
    return count + 1;
}

fn peelChoice(g: *const Embedding, path: *const [MAX_N]usize, length: usize) ?usize {
    var chord = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var chord_count: usize = 0;
    for (0..length) |left| {
        var right = left + 2;
        while (right < length) : (right += 1) {
            if (left == 0 and right + 1 == length) continue;
            if (g.adjacent[path.*[left]][path.*[right]]) {
                chord[left][right] = true;
                chord_count += 1;
            }
        }
    }
    var eligible = [_]bool{false} ** MAX_N;
    if (chord_count == 0) {
        for (1..length - 1) |i| eligible[path.*[i]] = true;
    } else {
        for (0..length) |left| {
            var right = left + 2;
            while (right < length) : (right += 1) {
                if (!chord[left][right]) continue;
                var minimal = true;
                var a = left;
                while (a < right and minimal) : (a += 1) {
                    var b = a + 2;
                    while (b <= right) : (b += 1) {
                        if (chord[a][b] and (a != left or b != right)) minimal = false;
                    }
                }
                if (minimal) for (left + 1..right) |i| eligible[path.*[i]] = true;
            }
        }
    }
    for (0..g.n) |vertex| if (eligible[vertex]) return vertex;
    return null;
}

fn peelContains(g: *const Embedding, path: *const [MAX_N]usize, length: usize, candidate: usize) bool {
    var chord = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var chord_count: usize = 0;
    for (0..length) |left| {
        var right = left + 2;
        while (right < length) : (right += 1) {
            if (left == 0 and right + 1 == length) continue;
            if (g.adjacent[path.*[left]][path.*[right]]) {
                chord[left][right] = true;
                chord_count += 1;
            }
        }
    }
    var eligible = [_]bool{false} ** MAX_N;
    if (chord_count == 0) {
        for (1..length - 1) |i| eligible[path.*[i]] = true;
    } else {
        for (0..length) |left| {
            var right = left + 2;
            while (right < length) : (right += 1) {
                if (!chord[left][right]) continue;
                var minimal = true;
                var a = left;
                while (a < right and minimal) : (a += 1) {
                    var b = a + 2;
                    while (b <= right) : (b += 1) {
                        if (chord[a][b] and (a != left or b != right)) minimal = false;
                    }
                }
                if (minimal) for (left + 1..right) |i| eligible[path.*[i]] = true;
            }
        }
    }
    return candidate < g.n and eligible[candidate];
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn canonical_order_schnyder_realizer(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > 57) return -1;
    const values = input_opt.?[0..length];
    const raw_n = values[0];
    if (raw_n < 3 or raw_n > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(raw_n);
    if (length < n + 4) return -1;
    const graph_length = length - n;
    const g = parseEmbedding(values[0..graph_length]) orelse return -1;
    if (g.n != n) return -1;
    var order = [_]usize{0} ** MAX_N;
    var order_seen = [_]bool{false} ** MAX_N;
    for (0..n) |i| {
        const raw = values[graph_length + i];
        if (raw < 0 or raw >= @as(i64, @intCast(n))) return -1;
        const vertex: usize = @intCast(raw);
        if (order_seen[vertex]) return -1;
        order[i] = vertex;
        order_seen[vertex] = true;
    }
    if (order[0] != g.u or order[1] != g.v or order[n - 1] != g.w) return -1;
    var active = [_]bool{false} ** MAX_N;
    @memset(active[0..n], true);
    var path = [_]usize{0} ** MAX_N;
    if (n > 3) {
        active[g.w] = false;
        var path_length = boundaryPath(&g, &active, &path) orelse return -1;
        var reverse_index = n - 2;
        while (reverse_index >= 3) {
            const candidate = order[reverse_index];
            if (candidate == g.u or candidate == g.v or !active[candidate] or
                !peelContains(&g, &path, path_length, candidate)) return -1;
            active[candidate] = false;
            path_length = boundaryPath(&g, &active, &path) orelse return -1;
            if (reverse_index == 3) break;
            reverse_index -= 1;
        }
        if (path_length != 3 or path[0] != g.u or path[1] != order[2] or path[2] != g.v) return -1;
    } else if (order[2] != g.w) return -1;
    var position = [_]usize{0} ** MAX_N;
    for (0..n) |i| position[order[i]] = i;
    var words = [_]i64{0} ** (1 + 4 * (MAX_N - 3));
    words[0] = @intCast(n);
    var count: usize = 1;
    for (2..n - 1) |rank| {
        const vertex = order[rank];
        var left: usize = 0;
        var right: usize = 0;
        if (rank == 2) {
            if (!g.adjacent[vertex][g.u] or !g.adjacent[vertex][g.v]) return -1;
            left = g.u;
            right = g.v;
        } else {
            var prefix = [_]bool{false} ** MAX_N;
            for (0..rank) |i| prefix[order[i]] = true;
            var boundary = [_]usize{0} ** MAX_N;
            const boundary_length = boundaryPath(&g, &prefix, &boundary) orelse return -1;
            if (boundary_length < 3) return -1;
            var first: ?usize = null;
            var last: usize = 0;
            var ended = false;
            var boundary_count: usize = 0;
            for (0..boundary_length) |i| {
                if (g.adjacent[vertex][boundary[i]]) {
                    if (ended) return -1;
                    if (first == null) first = boundary[i];
                    last = boundary[i];
                    boundary_count += 1;
                } else if (first != null) ended = true;
            }
            var predecessor_count: usize = 0;
            for (0..rank) |i| if (g.adjacent[vertex][order[i]]) { predecessor_count += 1; };
            if (boundary_count < 2 or boundary_count != predecessor_count) return -1;
            left = first orelse return -1;
            right = last;
        }
        var successor: ?usize = null;
        for (0..n) |other| {
            if (position[other] > rank and g.adjacent[vertex][other] and
                (successor == null or position[other] > position[successor.?])) successor = other;
        }
        const later = successor orelse return -1;
        words[count] = @intCast(vertex);
        words[count + 1] = @intCast(left);
        words[count + 2] = @intCast(right);
        words[count + 3] = @intCast(later);
        count += 4;
    }
    const required = 8 * count;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..count) |index| writeI64Le(output, 8 * index, words[index]);
    return @intCast(required);
}
