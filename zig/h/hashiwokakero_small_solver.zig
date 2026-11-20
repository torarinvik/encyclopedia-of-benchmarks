const MAX_ISLANDS: usize = 6;
const MAX_EDGE_SLOTS: usize = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 20;

const Solver = struct {
    island_count: usize = 0,
    edge_count: usize = 0,
    x: [MAX_ISLANDS]i64 = @splat(0),
    y: [MAX_ISLANDS]i64 = @splat(0),
    residual: [MAX_ISLANDS]i64 = @splat(0),
    remaining: [MAX_ISLANDS]usize = @splat(0),
    edge_u: [MAX_EDGE_SLOTS]usize = @splat(0),
    edge_v: [MAX_EDGE_SLOTS]usize = @splat(0),
    multiplicity: [MAX_EDGE_SLOTS]u8 = @splat(0),
    solution: [MAX_EDGE_SLOTS]u8 = @splat(0),
};

fn edgesCross(s: *const Solver, first: usize, second: usize) bool {
    const a = s.edge_u[first];
    const b = s.edge_v[first];
    const c = s.edge_u[second];
    const d = s.edge_v[second];
    const first_horizontal = s.y[a] == s.y[b];
    const second_horizontal = s.y[c] == s.y[d];
    if (first_horizontal == second_horizontal) return false;
    const h0 = if (first_horizontal) a else c;
    const h1 = if (first_horizontal) b else d;
    const v0 = if (first_horizontal) c else a;
    const v1 = if (first_horizontal) d else b;
    const hx = s.x[v0];
    const hy = s.y[h0];
    const hmin = @min(s.x[h0], s.x[h1]);
    const hmax = @max(s.x[h0], s.x[h1]);
    const vmin = @min(s.y[v0], s.y[v1]);
    const vmax = @max(s.y[v0], s.y[v1]);
    return hmin < hx and hx < hmax and vmin < hy and hy < vmax;
}

fn possibleGraphConnected(s: *const Solver, assigned_through: usize) bool {
    var reached: [MAX_ISLANDS]bool = @splat(false);
    var stack: [MAX_ISLANDS]usize = @splat(0);
    var top: usize = 1;
    reached[0] = true;
    stack[0] = 0;
    while (top != 0) {
        top -= 1;
        const island = stack[top];
        for (0..s.edge_count) |edge| {
            var usable = edge <= assigned_through and s.multiplicity[edge] != 0;
            if (edge > assigned_through) {
                usable = true;
                for (0..assigned_through + 1) |fixed| {
                    if (s.multiplicity[fixed] != 0 and edgesCross(s, fixed, edge)) {
                        usable = false;
                        break;
                    }
                }
            }
            if (!usable) continue;
            var neighbor = s.island_count;
            if (s.edge_u[edge] == island) {
                neighbor = s.edge_v[edge];
            } else if (s.edge_v[edge] == island) {
                neighbor = s.edge_u[edge];
            }
            if (neighbor < s.island_count and !reached[neighbor]) {
                reached[neighbor] = true;
                stack[top] = neighbor;
                top += 1;
            }
        }
    }
    for (0..s.island_count) |island| {
        if (!reached[island]) return false;
    }
    return true;
}

fn residualsFeasible(s: *const Solver) bool {
    for (0..s.island_count) |island| {
        if (s.residual[island] < 0 or s.residual[island] > @as(i64, @intCast(2 * s.remaining[island]))) return false;
    }
    return true;
}

fn search(s: *Solver, depth: usize) bool {
    if (depth == s.edge_count) {
        for (0..s.island_count) |island| {
            if (s.residual[island] != 0) return false;
        }
        if (!possibleGraphConnected(s, s.edge_count - 1)) return false;
        for (0..s.edge_count) |edge| s.solution[edge] = s.multiplicity[edge];
        return true;
    }

    const u = s.edge_u[depth];
    const v = s.edge_v[depth];
    s.remaining[u] -= 1;
    s.remaining[v] -= 1;
    for (0..3) |amount_usize| {
        const amount: u8 = @intCast(amount_usize);
        if (@as(i64, amount) > s.residual[u] or @as(i64, amount) > s.residual[v]) continue;
        var conflict = false;
        if (amount != 0) {
            for (0..depth) |prior| {
                if (s.multiplicity[prior] != 0 and edgesCross(s, prior, depth)) {
                    conflict = true;
                    break;
                }
            }
        }
        if (conflict) continue;
        s.multiplicity[depth] = amount;
        s.residual[u] -= @as(i64, amount);
        s.residual[v] -= @as(i64, amount);
        if (residualsFeasible(s) and possibleGraphConnected(s, depth) and search(s, depth + 1)) {
            s.residual[u] += @as(i64, amount);
            s.residual[v] += @as(i64, amount);
            s.remaining[u] += 1;
            s.remaining[v] += 1;
            return true;
        }
        s.residual[u] += @as(i64, amount);
        s.residual[v] += @as(i64, amount);
        s.multiplicity[depth] = 0;
    }
    s.remaining[u] += 1;
    s.remaining[v] += 1;
    return false;
}

export fn hashiwokakero_small_solver(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 2 or input[0] > MAX_ISLANDS) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3 * n) return -1;

    var s = Solver{ .island_count = n };
    for (0..n) |island| {
        const x = input[1 + 3 * island];
        const y = input[2 + 3 * island];
        const demand = input[3 + 3 * island];
        if (x < 0 or x > 7 or y < 0 or y > 7 or demand < 1 or demand > 8) return -1;
        for (0..island) |prior| {
            if (s.x[prior] == x and s.y[prior] == y) return -1;
        }
        s.x[island] = x;
        s.y[island] = y;
        s.residual[island] = demand;
    }

    for (0..n) |first| {
        for (first + 1..n) |second| {
            if (s.x[first] != s.x[second] and s.y[first] != s.y[second]) continue;
            var blocked = false;
            for (0..n) |middle| {
                if (middle == first or middle == second) continue;
                if (s.y[first] == s.y[second] and s.y[middle] == s.y[first] and
                    @min(s.x[first], s.x[second]) < s.x[middle] and s.x[middle] < @max(s.x[first], s.x[second])) blocked = true;
                if (s.x[first] == s.x[second] and s.x[middle] == s.x[first] and
                    @min(s.y[first], s.y[second]) < s.y[middle] and s.y[middle] < @max(s.y[first], s.y[second])) blocked = true;
            }
            if (!blocked) {
                if (s.edge_count == MAX_EDGE_SLOTS) return -1;
                const edge = s.edge_count;
                s.edge_count += 1;
                s.edge_u[edge] = first;
                s.edge_v[edge] = second;
                s.remaining[first] += 1;
                s.remaining[second] += 1;
            }
        }
    }

    if (!search(&s, 0)) return -2;
    var packed: i64 = @as(i64, 1) << 32;
    for (0..s.edge_count) |edge| {
        packed |= @as(i64, s.solution[edge]) << @intCast(2 * edge);
    }
    return packed;
}
