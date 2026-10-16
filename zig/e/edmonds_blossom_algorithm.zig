const MAX_V: usize = 20;
pub export fn edmonds_blossom_algorithm(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 0 or n0 > 20 or m0 < 0 or m0 > 190) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    if (length != 2 + 2 * m) return -1;
    var graph: [MAX_V * MAX_V]bool = @splat(false);
    for (0..m) |i| {
        const a = input[2 + 2 * i]; const b = input[3 + 2 * i];
        if (a < 0 or a >= n0 or b < 0 or b >= n0 or a == b) return -1;
        const u: usize = @intCast(a); const v: usize = @intCast(b);
        graph[u * MAX_V + v] = true; graph[v * MAX_V + u] = true;
    }
    var mate: [MAX_V]i64 = @splat(-1); var parent: [MAX_V]i64 = undefined; var base: [MAX_V]usize = undefined;
    var used: [MAX_V]bool = undefined; var blossom: [MAX_V]bool = undefined; var queue: [MAX_V]usize = undefined;
    var answer: i64 = 0;
    for (0..n) |root| {
        if (mate[root] != -1) continue;
        for (0..n) |i| { used[i] = false; parent[i] = -1; base[i] = i; }
        var head: usize = 0; var tail: usize = 0; queue[tail] = root; tail += 1; used[root] = true;
        var endpoint: i64 = -1;
        while (head < tail and endpoint == -1) {
            const v = queue[head]; head += 1;
            for (0..n) |u| {
                if (!graph[v * MAX_V + u] or base[v] == base[u] or mate[v] == @as(i64, @intCast(u))) continue;
                if (u == root or (mate[u] != -1 and parent[@intCast(mate[u])] != -1)) {
                    var path: [MAX_V]bool = @splat(false); var x = v; var y = u;
                    while (true) { x = base[x]; path[x] = true; if (mate[x] == -1) break; x = @intCast(parent[@intCast(mate[x])]); }
                    while (!path[base[y]]) y = @intCast(parent[@intCast(mate[base[y]])]);
                    const common = base[y]; for (0..n) |i| blossom[i] = false;
                    x = v; y = u;
                    while (base[x] != common) { blossom[base[x]] = true; blossom[base[@intCast(mate[x])]] = true; parent[x] = @intCast(y); y = @intCast(mate[x]); x = @intCast(parent[@intCast(mate[x])]); }
                    x = u; y = v;
                    while (base[x] != common) { blossom[base[x]] = true; blossom[base[@intCast(mate[x])]] = true; parent[x] = @intCast(y); y = @intCast(mate[x]); x = @intCast(parent[@intCast(mate[x])]); }
                    for (0..n) |i| if (blossom[base[i]]) { base[i] = common; if (!used[i]) { used[i] = true; queue[tail] = i; tail += 1; } };
                } else if (parent[u] == -1) {
                    parent[u] = @intCast(v);
                    if (mate[u] == -1) { endpoint = @intCast(u); break; }
                    const next: usize = @intCast(mate[u]); used[next] = true; queue[tail] = next; tail += 1;
                }
            }
        }
        if (endpoint != -1) {
            var v: i64 = endpoint;
            while (v != -1) { const pv = parent[@intCast(v)]; const next = mate[@intCast(pv)]; mate[@intCast(v)] = pv; mate[@intCast(pv)] = v; v = next; }
            if (mate[root] != -1) answer += 1;
        }
    }
    return answer;
}
