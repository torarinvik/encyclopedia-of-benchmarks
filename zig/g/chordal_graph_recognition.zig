const N: usize = 6;
const MAX_INPUT: usize = 32;
const MAX_OUTPUT: usize = 64;

fn putU64(out: *[MAX_OUTPUT]u8, index: usize, value: u64) void {
    for (0..8) |byte| out[index * 8 + byte] = @truncate(value >> @intCast(byte * 8));
}

fn inducedCycle(adjacent: *const [N][N]bool, n: usize, cycle: *[N]usize, cycle_len: *usize) bool {
    for (0..(@as(usize, 1) << @intCast(n))) |mask| {
        var vertices: [N]usize = @splat(0);
        var count: usize = 0;
        for (0..n) |v| if (mask & (@as(usize, 1) << @intCast(v)) != 0) { vertices[count] = v; count += 1; };
        if (count < 4) continue;
        var valid = true;
        for (0..count) |i| {
            var degree: usize = 0;
            for (0..count) |j| if (adjacent[vertices[i]][vertices[j]]) { degree += 1; };
            if (degree != 2) valid = false;
        }
        if (!valid) continue;
        var seen: [N]bool = @splat(false);
        var queue: [N]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 1;
        seen[vertices[0]] = true; queue[0] = vertices[0];
        while (head < tail) {
            const v = queue[head]; head += 1;
            for (0..count) |i| {
                const u = vertices[i];
                if (adjacent[v][u] and !seen[u]) { seen[u] = true; queue[tail] = u; tail += 1; }
            }
        }
        if (tail != count) continue;
        const start = vertices[0];
        var previous = start;
        var current: usize = start;
        for (0..count) |i| if (adjacent[start][vertices[i]]) { current = vertices[i]; break; };
        cycle[0] = start;
        for (1..count) |i| {
            cycle[i] = current;
            var next: usize = start;
            for (0..count) |j| if (adjacent[current][vertices[j]] and vertices[j] != previous) { next = vertices[j]; break; };
            previous = current; current = next;
        }
        cycle_len.* = count;
        return true;
    }
    return false;
}

fn isPeo(adjacent: *const [N][N]bool, order: *const [N]usize, n: usize) bool {
    var position: [N]usize = @splat(0);
    for (0..n) |i| position[order[i]] = i;
    for (0..n) |i| {
        const v = order[i];
        var parent: ?usize = null;
        for (0..n) |u| if (adjacent[v][u] and position[u] > i) {
            if (parent == null or position[u] < position[parent.?]) parent = u;
        };
        if (parent) |p| for (0..n) |u| {
            if (adjacent[v][u] and position[u] > i and u != p and !adjacent[p][u]) return false;
        };
    }
    return true;
}

export fn chordal_graph_recognition(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 6 or input[1] < 0 or input[1] > 15) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;
    var adjacent: [N][N]bool = @splat(@splat(false));
    for (0..m) |edge| {
        const a0 = input[2 + 2 * edge];
        const b0 = input[3 + 2 * edge];
        if (a0 < 0 or b0 < 0 or a0 >= @as(i64, @intCast(n)) or b0 >= @as(i64, @intCast(n)) or a0 == b0) return -1;
        const a: usize = @intCast(a0); const b: usize = @intCast(b0);
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = true; adjacent[b][a] = true;
    }
    var selected: [N]bool = @splat(false);
    var label: [N]usize = @splat(0);
    var reverse: [N]usize = @splat(0);
    for (0..n) |step| {
        var chosen: ?usize = null;
        for (0..n) |v| if (!selected[v]) {
            if (chosen == null or label[v] > label[chosen.?]) chosen = v;
        };
        const v = chosen.?; selected[v] = true; reverse[step] = v;
        for (0..n) |u| if (!selected[u] and adjacent[v][u]) { label[u] += 1; };
    }
    var order: [N]usize = @splat(0);
    for (0..n) |i| order[i] = reverse[n - i - 1];
    var packed: [8]u64 = @splat(0);
    var count: usize = 0;
    if (isPeo(&adjacent, &order, n)) {
        packed[count] = 1; count += 1;
        for (0..n) |i| { packed[count] = order[i]; count += 1; }
    } else {
        var cycle: [N]usize = @splat(0); var cycle_len: usize = 0;
        if (!inducedCycle(&adjacent, n, &cycle, &cycle_len)) return -1;
        packed[count] = 0; count += 1; packed[count] = cycle_len; count += 1;
        for (0..cycle_len) |i| { packed[count] = cycle[i]; count += 1; }
    }
    const bytes = count * 8;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    for (0..count) |i| putU64(&staged, i, packed[i]);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
