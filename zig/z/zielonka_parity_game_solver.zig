const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 20;
const MAX_PARSEABLE_INPUT: usize = 59;

fn zpgAttractor(active: u16, player: u8, target: u16, owners: [8]u8,
    adjacency: [8]u16, n: usize) u16 {
    var attracted = target;
    while (true) {
        var additions: u16 = 0;
        for (0..n) |vertex| {
            const bit: u16 = @as(u16, 1) << @intCast(vertex);
            if ((active & bit) == 0 or (attracted & bit) != 0) continue;
            const successors = adjacency[vertex] & active;
            if (owners[vertex] == player) {
                if ((successors & attracted) != 0) additions |= bit;
            } else if (successors != 0 and (successors & ~attracted) == 0) {
                additions |= bit;
            }
        }
        if (additions == 0) return attracted;
        attracted |= additions;
    }
}

fn zpgSolve(active: u16, owners: [8]u8, priorities: [8]u8, adjacency: [8]u16, n: usize) u16 {
    if (active == 0) return 0;
    var lowest: u8 = 6;
    for (0..n) |vertex| {
        const bit: u16 = @as(u16, 1) << @intCast(vertex);
        if ((active & bit) != 0 and priorities[vertex] < lowest) lowest = priorities[vertex];
    }
    const player: u8 = lowest & 1;
    var target: u16 = 0;
    for (0..n) |vertex| {
        const bit: u16 = @as(u16, 1) << @intCast(vertex);
        if ((active & bit) != 0 and priorities[vertex] == lowest) target |= bit;
    }
    const first = zpgAttractor(active, player, target, owners, adjacency, n);
    const remainder = active & ~first;
    const even_first = zpgSolve(remainder, owners, priorities, adjacency, n);
    const odd_first = remainder & ~even_first;
    const opponent_region = if (player == 1) even_first else odd_first;
    if (opponent_region == 0) return even_first | (if (player == 0) first else 0);
    const second = zpgAttractor(active, 1 - player, opponent_region, owners, adjacency, n);
    const even_second = zpgSolve(active & ~second, owners, priorities, adjacency, n);
    return even_second | (if (player == 1) second else 0);
}

export fn zielonka_parity_game_solver(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 6 or length > MAX_PARSEABLE_INPUT) return -1;
    const vertex_raw = input[0];
    const edge_raw = input[1];
    if (vertex_raw < 1 or vertex_raw > 8 or edge_raw < vertex_raw or edge_raw > 20) return -1;
    const n: usize = @intCast(vertex_raw);
    const edge_count: usize = @intCast(edge_raw);
    if (length != 2 + 2 * n + 2 * edge_count) return -1;

    var owners: [8]u8 = .{0} ** 8;
    var priorities: [8]u8 = .{0} ** 8;
    var adjacency: [8]u16 = .{0} ** 8;
    var outdegree: [8]usize = .{0} ** 8;
    var cursor: usize = 2;
    for (0..n) |vertex| {
        const owner = input[cursor];
        const priority = input[cursor + 1];
        cursor += 2;
        if (owner < 0 or owner > 1 or priority < 0 or priority > 5) return -1;
        owners[vertex] = @intCast(owner);
        priorities[vertex] = @intCast(priority);
    }
    for (0..edge_count) |_| {
        const source_raw = input[cursor];
        const destination_raw = input[cursor + 1];
        cursor += 2;
        if (source_raw < 0 or source_raw >= vertex_raw or destination_raw < 0 or destination_raw >= vertex_raw) return -1;
        const source: usize = @intCast(source_raw);
        const destination: usize = @intCast(destination_raw);
        const bit: u16 = @as(u16, 1) << @intCast(destination);
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        outdegree[source] += 1;
    }
    for (0..n) |vertex| if (outdegree[vertex] == 0) return -1;
    return @intCast(zpgSolve((@as(u16, 1) << @intCast(n)) - 1, owners, priorities, adjacency, n));
}
