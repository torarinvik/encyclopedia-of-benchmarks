// Uncompiled matching-sensitivity tree edge-coloring draft.
const inf: i64 = 1_000_000_000_000_000;

fn assignment(d: usize, width: usize, cost: *const [16][16]i64, deletion: *[16]i64) i64 {
    var row_dual = [_]i64{0} ** 17;
    var col_dual = [_]i64{0} ** 17;
    var owner = [_]usize{0} ** 17;
    for (1..d+1) |row| {
        var previous = [_]usize{0} ** 17;
        var used = [_]bool{false} ** 17;
        var slack = [_]i64{inf} ** 17;
        owner[0] = row;
        var col: usize = 0;
        while (true) {
            used[col] = true;
            const active = owner[col];
            var step: i64 = inf;
            var next_col: usize = 0;
            for (1..width+1) |candidate| {
                if (used[candidate]) continue;
                const reduced = cost[active-1][candidate-1] - row_dual[active] - col_dual[candidate];
                if (reduced < slack[candidate]) { slack[candidate] = reduced; previous[candidate] = col; }
                if (slack[candidate] < step) { step = slack[candidate]; next_col = candidate; }
            }
            if (next_col == 0) return -1;
            for (0..width+1) |candidate| {
                if (used[candidate]) { row_dual[owner[candidate]] += step; col_dual[candidate] -= step; }
                else if (candidate != 0) { slack[candidate] -= step; }
            }
            col = next_col;
            if (owner[col] == 0) break;
        }
        while (col != 0) {
            const parent = previous[col];
            owner[col] = owner[parent];
            col = parent;
        }
    }
    var base: i64 = 0;
    var free_col: usize = width;
    for (0..width) |col| {
        if (owner[col+1] != 0) base += cost[owner[col+1]-1][col] else free_col = col;
    }
    if (width == d) return base;
    if (free_col == width) return -1;
    var distance = [_]i64{inf} ** 16;
    distance[free_col] = 0;
    for (0..d) |_| {
        var updated = distance;
        for (0..width) |col| {
            if (owner[col+1] == 0) continue;
            const row = owner[col+1]-1;
            for (0..width) |dest| {
                if (distance[dest] != inf)
                    updated[col] = @min(updated[col], cost[row][dest]-cost[row][col]+distance[dest]);
            }
        }
        distance = updated;
    }
    for (0..width) |col| {
        if (distance[col] == inf) return -1;
        deletion[col] = base + distance[col];
    }
    return base;
}

export fn tree_min_cost_edge_coloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 82) return -1;
    const nv = input[0]; const kv = input[1];
    if (nv < 1 or nv > 64 or kv < 1 or kv > 16) return -1;
    const n: usize = @intCast(nv); const k: usize = @intCast(kv);
    if (length != n+1+k) return -1;
    var parents = [_]usize{0} ** 64;
    var degree = [_]usize{0} ** 64;
    var child_count = [_]usize{0} ** 64;
    for (1..n) |vertex| {
        const parent = input[1+vertex];
        if (parent < 0 or parent >= @as(i64, @intCast(vertex))) return -1;
        parents[vertex] = @intCast(parent);
        degree[parents[vertex]] += 1; degree[vertex] += 1;
    }
    var prices = [_]i64{0} ** 16;
    for (0..k) |c| {
        const value = input[n+1+c];
        if (value < 0 or value > 1_000_000) return -1;
        prices[c] = value;
    }
    for (0..n) |vertex| if (degree[vertex] > k) { return -2; };
    for (1..k) |color| {
        const value = prices[color];
        var j = color;
        while (j > 0 and prices[j-1] > value) : (j -= 1) prices[j] = prices[j-1];
        prices[j] = value;
    }
    var children = [_][16]usize{[_]usize{0} ** 16} ** 64;
    for (1..n) |vertex| {
        const parent = parents[vertex];
        children[parent][child_count[parent]] = vertex;
        child_count[parent] += 1;
    }
    var tables = [_][16]i64{[_]i64{0} ** 16} ** 64;
    var vertex = n;
    while (vertex > 0) {
        vertex -= 1;
        const d = child_count[vertex];
        if (d == 0) continue;
        const saturated = vertex == 0 and d == k;
        const width = if (saturated) d else d+1;
        var cost = [_][16]i64{[_]i64{0} ** 16} ** 16;
        for (0..d) |row| {
            const child = children[vertex][row];
            for (0..width) |col|
                cost[row][col] = prices[col] + tables[child][@min(col, child_count[child])];
        }
        var deletion = [_]i64{0} ** 16;
        const base = assignment(d, width, &cost, &deletion);
        if (base < 0) return -1;
        if (saturated) tables[vertex][0] = base else {
            for (0..width) |col| tables[vertex][col] = deletion[col];
        }
    }
    return if (child_count[0] == k) tables[0][0] else tables[0][child_count[0]];
}
