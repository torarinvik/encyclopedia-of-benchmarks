// Clean-room bounded GBBS MPX low-diameter decomposition profile.
const n_max: usize = 12;
const m_max: usize = 24;
const input_max: usize = 2 + 2 * m_max;
const batch = [_]usize{ 1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11 };

export fn gbbs_low_diameter_decomposition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > input_max) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 12 or m64 < 0 or m64 > 24
        or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_][n_max]bool{[_]bool{false} ** n_max} ** n_max;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if (output_opt == null or capacity < n) return -2;
    const output = output_opt.?;

    var labels = [_]i16{-1} ** n_max;
    var frontier = [_]usize{0} ** n_max;
    var frontier_count: usize = 0;
    var cursor: usize = 0;
    var assigned: usize = 0;
    var round: usize = 0;
    while (assigned < n) {
        const possible_end = cursor + batch[round];
        const end = if (possible_end < n) possible_end else n;
        for (cursor..end) |candidate| {
            if (labels[candidate] < 0) {
                labels[candidate] = @intCast(candidate);
                frontier[frontier_count] = candidate;
                frontier_count += 1;
                assigned += 1;
            }
        }
        cursor = end;
        if (assigned == n) break;

        var reached = [_]i16{-1} ** n_max;
        for (frontier[0..frontier_count]) |vertex| {
            for (0..n) |neighbor| {
                if (adjacent[vertex][neighbor] and labels[neighbor] < 0
                    and (reached[neighbor] < 0 or labels[vertex] < reached[neighbor])) {
                    reached[neighbor] = labels[vertex];
                }
            }
        }
        frontier_count = 0;
        for (0..n) |vertex| {
            if (reached[vertex] >= 0) {
                labels[vertex] = reached[vertex];
                frontier[frontier_count] = vertex;
                frontier_count += 1;
                assigned += 1;
            }
        }
        round += 1;
    }
    for (0..n) |vertex| output[vertex] = @intCast(labels[vertex]);
    return @intCast(n);
}
