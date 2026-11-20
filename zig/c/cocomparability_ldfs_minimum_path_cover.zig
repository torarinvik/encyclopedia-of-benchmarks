const max_n: usize = 8;
const max_parseable: usize = 18;

export fn cocomparability_ldfs_minimum_path_cover(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > max_parseable) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(words[0]);
    if (length != 1 + 2 * n) return -1;
    const full: u16 = (@as(u16, 1) << @intCast(n)) - 1;
    var adjacency = [_]u16{0} ** max_n;
    var order = [_]usize{0} ** max_n;
    var rank = [_]usize{0} ** max_n;
    var position = [_]usize{0} ** max_n;
    var seen_order = [_]bool{false} ** max_n;
    for (0..n) |v| {
        const row = words[1 + v];
        if (row < 0 or row > @as(i64, @intCast(full)) or (row & (@as(i64, 1) << @intCast(v))) != 0) return -1;
        adjacency[v] = @intCast(row);
    }
    for (0..n) |u| {
        for (0..n) |v| {
            if (((adjacency[u] >> @intCast(v)) & 1) != ((adjacency[v] >> @intCast(u)) & 1)) return -1;
        }
    }
    for (0..n) |i| {
        const value = words[1 + n + i];
        if (value < 0 or value >= @as(i64, @intCast(n))) return -1;
        const v: usize = @intCast(value);
        if (seen_order[v]) return -1;
        order[i] = v;
        rank[v] = i;
        seen_order[v] = true;
    }
    for (0..n) |i| {
        for (i + 1..n) |j| {
            for (j + 1..n) |k| {
                const a = order[i];
                const b = order[j];
                const c = order[k];
                if (((adjacency[a] >> @intCast(c)) & 1) != 0 and
                    ((adjacency[a] >> @intCast(b)) & 1) == 0 and
                    ((adjacency[b] >> @intCast(c)) & 1) == 0) return -1;
            }
        }
    }
    var reached = [_]bool{false} ** max_n;
    var queue = [_]usize{0} ** max_n;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = 0;
    reached[0] = true;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..n) |v| {
            if ((adjacency[u] & (@as(u16, 1) << @intCast(v))) != 0 and !reached[v]) {
                reached[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    for (0..n) |v| if (!reached[v]) return -1;

    var labels = [_]u64{0} ** max_n;
    var visited = [_]bool{false} ** max_n;
    var ldfs = [_]usize{0} ** max_n;
    for (1..n + 1) |step| {
        var chosen: usize = max_n;
        for (0..n) |v| {
            if (visited[v]) continue;
            if (chosen == max_n or labels[v] > labels[chosen] or
                (labels[v] == labels[chosen] and rank[v] > rank[chosen])) chosen = v;
        }
        ldfs[step - 1] = chosen;
        visited[chosen] = true;
        for (0..n) |v| {
            if (!visited[v] and (adjacency[chosen] & (@as(u16, 1) << @intCast(v))) != 0) {
                labels[v] = (labels[v] >> 4) | (@as(u64, @intCast(step)) << 60);
            }
        }
    }
    for (0..n) |i| position[ldfs[i]] = i;
    for (0..n) |v| visited[v] = false;
    var paths: i64 = 0;
    while (true) {
        var current: usize = max_n;
        for (0..n) |v| {
            if (!visited[v] and (current == max_n or position[v] > position[current])) current = v;
        }
        if (current == max_n) break;
        paths += 1;
        visited[current] = true;
        while (true) {
            var next: usize = max_n;
            for (0..n) |v| {
                if (!visited[v] and (adjacency[current] & (@as(u16, 1) << @intCast(v))) != 0 and
                    (next == max_n or position[v] > position[next])) next = v;
            }
            if (next == max_n) break;
            visited[next] = true;
            current = next;
        }
    }
    return paths;
}
