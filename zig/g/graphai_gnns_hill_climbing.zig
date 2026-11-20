const MAX_N: usize = 16;
const MAX_D: usize = 4;
const MAX_INPUT: usize = 89;
const MAX_PARSEABLE: usize = 90;
const COORD_LIMIT: i64 = 100;
const DISTANCE_RADIX: i64 = 160001;

export fn graphai_gnns_hill_climbing(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 5 or length > MAX_PARSEABLE) return -1;
    const n_value = input[0];
    const d_value = input[1];
    const start_value = input[2];
    const e_value = input[3];
    const t_value = input[4];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_N))
        or d_value < 1 or d_value > @as(i64, @intCast(MAX_D))) return -1;
    if (start_value < 0 or start_value >= n_value or e_value < 1 or e_value >= n_value
        or t_value < 0 or t_value > 16) return -1;
    const n: usize = @intCast(n_value);
    const d: usize = @intCast(d_value);
    if (length != 5 + n * d + n + d or length > MAX_INPUT) return -1;

    var coordinates: [MAX_N * MAX_D]i64 = @splat(0);
    for (0..n * d) |index| {
        const coordinate = input[5 + index];
        if (coordinate < -COORD_LIMIT or coordinate > COORD_LIMIT) return -1;
        coordinates[index] = coordinate;
    }
    const mask_offset = 5 + n * d;
    const allowed: i64 = (@as(i64, 1) << @as(u6, @intCast(n))) - 1;
    var masks: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| {
        const mask = input[mask_offset + vertex];
        const bit: i64 = @as(i64, 1) << @as(u6, @intCast(vertex));
        if (mask < 0 or (mask & ~allowed) != 0 or (mask & bit) != 0) return -1;
        masks[vertex] = mask;
    }
    var query: [MAX_D]i64 = @splat(0);
    for (0..d) |axis| {
        const coordinate = input[mask_offset + n + axis];
        if (coordinate < -COORD_LIMIT or coordinate > COORD_LIMIT) return -1;
        query[axis] = coordinate;
    }

    var current: usize = @intCast(start_value);
    var current_distance: i64 = 0;
    for (0..d) |axis| {
        const delta = coordinates[current * d + axis] - query[axis];
        current_distance += delta * delta;
    }
    var evaluations: i64 = 1;
    var moves: i64 = 0;
    for (0..@as(usize, @intCast(t_value))) |_| {
        var best_vertex = current;
        var best_distance = current_distance;
        var inspected: i64 = 0;
        for (0..n) |vertex| {
            const bit: i64 = @as(i64, 1) << @as(u6, @intCast(vertex));
            if ((masks[current] & bit) == 0) continue;
            var distance: i64 = 0;
            for (0..d) |axis| {
                const delta = coordinates[vertex * d + axis] - query[axis];
                distance += delta * delta;
            }
            evaluations += 1;
            inspected += 1;
            if (distance < best_distance or (distance == best_distance and vertex < best_vertex)) {
                best_vertex = vertex;
                best_distance = distance;
            }
            if (inspected == e_value) break;
        }
        if (best_distance >= current_distance) break;
        current = best_vertex;
        current_distance = best_distance;
        moves += 1;
    }
    return (((evaluations * 17 + moves) * 16 + @as(i64, @intCast(current))) * DISTANCE_RADIX
        + current_distance);
}
