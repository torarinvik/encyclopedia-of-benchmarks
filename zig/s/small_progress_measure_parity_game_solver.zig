const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 20;
const MAX_INPUT: usize = 59;
const Rank = [3]u8;

const Progress = struct { rank: Rank, top: bool };

fn compare(left: Rank, left_top: bool, right: Rank, right_top: bool) i8 {
    if (left_top != right_top) return if (left_top) 1 else -1;
    if (left_top) return 0;
    for (0..3) |index| {
        if (left[index] < right[index]) return -1;
        if (left[index] > right[index]) return 1;
    }
    return 0;
}

fn progress(target: Rank, target_top: bool, priority: u8, bounds: Rank) Progress {
    var result = target;
    if (target_top) return .{ .rank = result, .top = true };
    const included: usize = if (priority < 1) 0 else if (priority < 3) 1 else if (priority < 5) 2 else 3;
    for (included..3) |index| result[index] = 0;
    if (priority % 2 == 0) return .{ .rank = result, .top = false };
    var cursor = included;
    while (cursor > 0) {
        cursor -= 1;
        if (result[cursor] < bounds[cursor]) {
            result[cursor] += 1;
            for (cursor + 1..included) |suffix| result[suffix] = 0;
            return .{ .rank = result, .top = false };
        }
        result[cursor] = 0;
    }
    return .{ .rank = .{ 0, 0, 0 }, .top = true };
}

export fn small_progress_measure_parity_game_solver(
    input_opt: ?[*]const i64,
    length: usize,
) callconv(.c) i64 {
    const input = input_opt orelse return -1;
    if (length < 6 or length > MAX_INPUT) return -1;
    const n_raw = input[0];
    const m_raw = input[1];
    if (n_raw < 1 or n_raw > MAX_VERTICES or m_raw < n_raw or m_raw > MAX_EDGES) return -1;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);
    if (length != 2 + 2 * n + 2 * m) return -1;

    var owners = [_]u8{0} ** MAX_VERTICES;
    var priorities = [_]u8{0} ** MAX_VERTICES;
    var adjacency = [_]u16{0} ** MAX_VERTICES;
    var outdegree = [_]u8{0} ** MAX_VERTICES;
    var bounds: Rank = .{ 0, 0, 0 };
    var measures = [_]Rank{.{ 0, 0, 0 }} ** MAX_VERTICES;
    var tops = [_]bool{false} ** MAX_VERTICES;
    var cursor: usize = 2;
    for (0..n) |vertex| {
        const owner = input[cursor];
        const priority = input[cursor + 1];
        cursor += 2;
        if (owner < 0 or owner > 1 or priority < 0 or priority > 5) return -1;
        owners[vertex] = @intCast(owner);
        priorities[vertex] = @intCast(priority);
        if (priority == 1) bounds[0] += 1;
        if (priority == 3) bounds[1] += 1;
        if (priority == 5) bounds[2] += 1;
    }
    for (0..m) |_| {
        const source_raw = input[cursor];
        const destination_raw = input[cursor + 1];
        cursor += 2;
        if (source_raw < 0 or source_raw >= n_raw or destination_raw < 0 or destination_raw >= n_raw)
            return -1;
        const source: usize = @intCast(source_raw);
        const destination: usize = @intCast(destination_raw);
        const bit: u16 = @as(u16, 1) << @intCast(destination);
        if (adjacency[source] & bit != 0) return -1;
        adjacency[source] |= bit;
        outdegree[source] += 1;
    }
    for (0..n) |vertex| if (outdegree[vertex] == 0) return -1;

    while (true) {
        var changed = false;
        for (0..n) |vertex| {
            var best: Rank = .{ 0, 0, 0 };
            var best_top = owners[vertex] == 1;
            var has_best = false;
            for (0..n) |destination| {
                const bit: u16 = @as(u16, 1) << @intCast(destination);
                if (adjacency[vertex] & bit == 0) continue;
                const candidate = progress(measures[destination], tops[destination], priorities[vertex], bounds);
                const order = compare(candidate.rank, candidate.top, best, best_top);
                if (!has_best or (owners[vertex] == 0 and order < 0) or (owners[vertex] == 1 and order > 0)) {
                    best = candidate.rank;
                    best_top = candidate.top;
                    has_best = true;
                }
            }
            if (compare(measures[vertex], tops[vertex], best, best_top) < 0) {
                measures[vertex] = best;
                tops[vertex] = best_top;
                changed = true;
            }
        }
        if (!changed) break;
    }
    var winners: i64 = 0;
    for (0..n) |vertex| if (!tops[vertex]) winners |= @as(i64, 1) << @intCast(vertex);
    return winners;
}
