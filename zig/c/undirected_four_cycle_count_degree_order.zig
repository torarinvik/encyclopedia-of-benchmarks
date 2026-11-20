// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
const max_n: usize = 16;
const max_m: usize = 64;

export fn undirected_four_cycle_count_degree_order(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 131) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(max_n)) or m64 < 0 or
        m64 > @as(i64, @intCast(max_m))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;

    var neighbors = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var degree = [_]usize{0} ** max_n;
    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 >= v64) return -1;
        if (edge != 0 and (u64 < previous_u or (u64 == previous_u and v64 <= previous_v))) return -1;
        previous_u = u64;
        previous_v = v64;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        neighbors[u][degree[u]] = v;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        degree[v] += 1;
    }

    var order = [_]usize{0} ** max_n;
    var rank = [_]usize{0} ** max_n;
    for (0..n) |i| order[i] = i;
    for (1..n) |i| {
        const key = order[i];
        var j = i;
        while (j > 0) {
            const prior = order[j - 1];
            if (degree[prior] < degree[key] or
                (degree[prior] == degree[key] and prior < key)) break;
            order[j] = prior;
            j -= 1;
        }
        order[j] = key;
    }
    for (0..n) |i| rank[order[i]] = i;

    var count = [_]i64{0} ** max_n;
    var total: i64 = 0;
    for (0..n) |position| {
        const pivot = order[position];
        for (0..degree[pivot]) |bi| {
            const middle = neighbors[pivot][bi];
            if (rank[middle] >= position) continue;
            for (0..degree[middle]) |ci| {
                const opposite = neighbors[middle][ci];
                if (rank[opposite] < position) {
                    total += count[opposite];
                    count[opposite] += 1;
                }
            }
        }
        for (0..n) |vertex| count[vertex] = 0;
    }
    return total;
}
