// Clean-room bounded Kanj--Perkovic modified-Yao selection pass.
const N: usize = 16;
const M: usize = 42;
const K: usize = 14;
const D: usize = 84;
const MAX_VALID: usize = 312;
const MAX_PARSEABLE: usize = 313;

export fn kanj_perkovic_modified_yao_spanner(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 3 or n64 > @as(i64, N) or m64 < n64 - 1 or m64 > @as(i64, M) or m64 > 3 * n64 - 6) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const dcount = 2 * m;
    if (length != 2 + n + 7 * m or length > MAX_VALID) return -1;

    var edge_u: [M]usize = @splat(0);
    var edge_v: [M]usize = @splat(0);
    var weight: [M]i64 = @splat(0);
    var adjacent: [N * N]bool = @splat(false);
    var expected_degree: [N]usize = @splat(0);
    var source: [D]usize = @splat(0);
    var cone: [D]usize = @splat(0);
    for (0..m) |e| {
        const p = 2 + 5 * e;
        const u64 = input[p];
        const v64 = input[p + 1];
        const w = input[p + 2];
        const cu64 = input[p + 3];
        const cv64 = input[p + 4];
        if (u64 < 0 or u64 >= v64 or v64 >= n64 or w < 1 or w > 1_000_000_000_000 or
            cu64 < 0 or cu64 >= @as(i64, K) or cv64 < 0 or cv64 >= @as(i64, K)) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (e > 0 and (u < edge_u[e - 1] or (u == edge_u[e - 1] and v <= edge_v[e - 1]))) return -1;
        const cu: usize = @intCast(cu64);
        const cv: usize = @intCast(cv64);
        edge_u[e] = u; edge_v[e] = v; weight[e] = w;
        adjacent[u * N + v] = true; adjacent[v * N + u] = true;
        expected_degree[u] += 1; expected_degree[v] += 1;
        source[2 * e] = u; source[2 * e + 1] = v;
        cone[2 * e] = cu; cone[2 * e + 1] = cv;
    }

    var rotation: [D]usize = @splat(0);
    var position: [D]usize = @splat(0);
    var row_start: [N]usize = @splat(0);
    var degree: [N]usize = @splat(0);
    var first: [N * K]i16 = @splat(-1);
    var after: [N * K]i16 = @splat(-1);
    var seen: [D]bool = @splat(false);
    var cursor: usize = 2 + 5 * m;
    var used: usize = 0;
    for (0..n) |v| {
        const d64 = input[cursor]; cursor += 1;
        if (d64 < 1 or d64 > @as(i64, D) or @as(usize, @intCast(d64)) != expected_degree[v]) return -1;
        const d: usize = @intCast(d64);
        row_start[v] = used; degree[v] = d;
        var previous: i64 = -1;
        for (0..d) |_| {
            const raw = input[cursor]; cursor += 1;
            if (raw < 0 or raw >= @as(i64, @intCast(dcount))) return -1;
            const dart: usize = @intCast(raw);
            const c = cone[dart];
            if (seen[dart] or source[dart] != v or @as(i64, @intCast(c)) < previous) return -1;
            previous = @intCast(c); seen[dart] = true;
            rotation[used] = dart; position[dart] = used;
            const bucket = v * K + c;
            if (first[bucket] < 0) first[bucket] = @intCast(used);
            after[bucket] = @intCast(used + 1);
            used += 1;
        }
    }
    if (cursor != length or used != dcount) return -1;
    for (0..dcount) |d| if (!seen[d]) return -1;

    var reached: [N]bool = @splat(false);
    var queue: [N]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = 0; reached[0] = true;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| {
            if (adjacent[u * N + v] and !reached[v]) { reached[v] = true; queue[tail] = v; tail += 1; }
        }
    }
    if (tail != n) return -1;

    var next_face: [D]usize = @splat(0);
    var face_seen: [D]bool = @splat(false);
    var faces: usize = 0;
    for (0..dcount) |d| {
        const twin = d ^ 1;
        const dest = source[twin];
        const local = position[twin] - row_start[dest];
        next_face[d] = rotation[row_start[dest] + (local + degree[dest] - 1) % degree[dest]];
    }
    for (0..dcount) |d| {
        if (!face_seen[d]) {
            faces += 1;
            var current = d;
            while (!face_seen[current]) { face_seen[current] = true; current = next_face[current]; }
            if (current != d) return -1;
        }
    }
    if (@as(i64, @intCast(n)) - @as(i64, @intCast(m)) + @as(i64, @intCast(faces)) != 2) return -1;

    var selected: [D]bool = @splat(false);
    for (0..n) |v| {
        for (0..K) |c| {
            const bucket = v * K + c;
            if (first[bucket] < 0) continue;
            const lo: usize = @intCast(first[bucket]);
            const hi: usize = @intCast(after[bucket]);
            var best: usize = D;
            for (lo..hi) |p| {
                const dart = rotation[p];
                const e = dart / 2;
                if (best == D or weight[e] < weight[best / 2] or (weight[e] == weight[best / 2] and e < best / 2)) best = dart;
            }
            selected[best] = true;
        }
    }
    for (0..n) |v| {
        var occupied = false;
        for (0..K) |c| if (first[v * K + c] >= 0) { occupied = true; };
        if (!occupied) continue;
        for (0..K) |start| {
            if (first[v * K + start] >= 0 or first[v * K + (start + K - 1) % K] < 0) continue;
            var run: usize = 0;
            while (run < K and first[v * K + (start + run) % K] < 0) run += 1;
            if (run == 1) {
                const cw_c = (start + K - 1) % K;
                const ccw_c = (start + 1) % K;
                const cw = rotation[@as(usize, @intCast(after[v * K + cw_c])) - 1];
                const ccw = rotation[@intCast(first[v * K + ccw_c])];
                if (selected[cw]) selected[ccw] = true else if (selected[ccw]) selected[cw] = true else {
                    const a = cw / 2; const b = ccw / 2;
                    selected[if (weight[a] < weight[b] or (weight[a] == weight[b] and a < b)) cw else ccw] = true;
                }
            } else {
                var cw_left = run / 2;
                var ccw_left = (run + 1) / 2;
                for (1..K + 1) |step| {
                    if (cw_left == 0) break;
                    const c = (start + K - step) % K;
                    const bucket = v * K + c;
                    if (first[bucket] >= 0) {
                        var p: usize = @intCast(after[bucket]);
                        while (p > @as(usize, @intCast(first[bucket])) and cw_left > 0) {
                            p -= 1;
                            const dart = rotation[p];
                            if (!selected[dart]) { selected[dart] = true; cw_left -= 1; }
                        }
                    }
                }
                for (run..run + K) |step| {
                    if (ccw_left == 0) break;
                    const c = (start + step) % K;
                    const bucket = v * K + c;
                    if (first[bucket] >= 0) {
                        var p: usize = @intCast(first[bucket]);
                        while (p < @as(usize, @intCast(after[bucket])) and ccw_left > 0) : (p += 1) {
                            const dart = rotation[p];
                            if (!selected[dart]) { selected[dart] = true; ccw_left -= 1; }
                        }
                    }
                }
            }
        }
    }
    var mask: u64 = 0;
    for (0..m) |e| if (selected[2 * e] and selected[2 * e + 1]) { mask |= @as(u64, 1) << @intCast(e); };
    return @intCast(mask);
}
