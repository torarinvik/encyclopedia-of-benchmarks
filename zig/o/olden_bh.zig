const MIN_BODIES: usize = 2;
const MAX_BODIES: usize = 16;
const MAX_NODES: usize = 1024;
const MAX_DEPTH: usize = 16;

const Body = struct { position: [3]f64 = @splat(0.0), mass: f64 = 0.0 };
const Cell = struct { body: i32 = -1, child: [8]i32 = @splat(-1), mass: f64 = 0.0, center: [3]f64 = @splat(0.0) };
const Context = struct { bodies: [MAX_BODIES]Body = @splat(.{}), cells: [MAX_NODES]Cell = @splat(.{}), used: usize = 0 };

fn octant(position: [3]f64, center: [3]f64) usize {
    var result: usize = 0;
    if (position[0] >= center[0]) result |= 1;
    if (position[1] >= center[1]) result |= 2;
    if (position[2] >= center[2]) result |= 4;
    return result;
}

fn newCell(ctx: *Context) ?usize {
    if (ctx.used >= MAX_NODES) return null;
    const index = ctx.used;
    ctx.used += 1;
    ctx.cells[index] = .{};
    return index;
}

fn insertBody(ctx: *Context, cell_index: usize, body_index: usize, center: [3]f64, half: f64, depth: usize) bool {
    const old_body = ctx.cells[cell_index].body;
    if (old_body == -1) { ctx.cells[cell_index].body = @intCast(body_index); return true; }
    if (depth >= MAX_DEPTH) return false;
    if (old_body >= 0) ctx.cells[cell_index].body = -2;
    const item_count: usize = if (old_body >= 0) 2 else 1;
    for (0..item_count) |item_index| {
        const which_body: usize = if (old_body >= 0 and item_index == 0) @intCast(old_body) else body_index;
        const child = octant(ctx.bodies[which_body].position, center);
        if (ctx.cells[cell_index].child[child] < 0) {
            const created = newCell(ctx) orelse return false;
            ctx.cells[cell_index].child[child] = @intCast(created);
        }
        var next_center: [3]f64 = undefined;
        for (0..3) |axis| {
            const direction = if (child & (@as(usize, 1) << @intCast(axis)) != 0) half / 2.0 else -half / 2.0;
            next_center[axis] = center[axis] + direction;
        }
        if (!insertBody(ctx, @intCast(ctx.cells[cell_index].child[child]), which_body, next_center, half / 2.0, depth + 1)) return false;
    }
    return true;
}

fn aggregate(ctx: *Context, cell_index: usize) void {
    const body = ctx.cells[cell_index].body;
    if (body >= 0) {
        ctx.cells[cell_index].mass = ctx.bodies[@intCast(body)].mass;
        ctx.cells[cell_index].center = ctx.bodies[@intCast(body)].position;
        return;
    }
    var weighted: [3]f64 = @splat(0.0);
    ctx.cells[cell_index].mass = 0.0;
    for (0..8) |child| {
        const child_value = ctx.cells[cell_index].child[child];
        if (child_value < 0) continue;
        const child_index: usize = @intCast(child_value);
        aggregate(ctx, child_index);
        ctx.cells[cell_index].mass += ctx.cells[child_index].mass;
        for (0..3) |axis| weighted[axis] += ctx.cells[child_index].mass * ctx.cells[child_index].center[axis];
    }
    for (0..3) |axis| ctx.cells[cell_index].center[axis] = weighted[axis] / ctx.cells[cell_index].mass;
}

fn interact(mass: f64, position: [3]f64, query: [3]f64, eps_sq: f64, potential: *f64, acceleration: *[3]f64) void {
    var d: [3]f64 = undefined;
    var r2 = eps_sq;
    for (0..3) |axis| { d[axis] = position[axis] - query[axis]; r2 += d[axis] * d[axis]; }
    const contribution = mass / @sqrt(r2);
    potential.* -= contribution;
    const scale = contribution / r2;
    for (0..3) |axis| acceleration[axis] += d[axis] * scale;
}

fn walk(ctx: *const Context, cell_index: usize, side: f64, theta_sq: f64, query: [3]f64, eps_sq: f64, potential: *f64, acceleration: *[3]f64) void {
    const cell = ctx.cells[cell_index];
    if (cell.body >= 0) {
        const body = ctx.bodies[@intCast(cell.body)];
        interact(body.mass, body.position, query, eps_sq, potential, acceleration);
        return;
    }
    var distance_sq: f64 = 0.0;
    for (0..3) |axis| { const d = cell.center[axis] - query[axis]; distance_sq += d * d; }
    if (theta_sq * distance_sq < side * side) {
        for (0..8) |child| {
            const child_value = cell.child[child];
            if (child_value >= 0) walk(ctx, @intCast(child_value), side / 2.0, theta_sq, query, eps_sq, potential, acceleration);
        }
    } else interact(cell.mass, cell.center, query, eps_sq, potential, acceleration);
}

export fn olden_bh(input: [*c]const f64, input_length: usize, output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 6) return -1;
    const requested_count = input[0];
    const theta = input[1];
    const softening = input[2];
    if (!(requested_count >= 2.0 and requested_count <= 16.0) or !(theta >= 0.0 and theta <= 2.0) or !(softening >= 0.0 and softening <= 1.0)) return -1;
    if (@as(f64, @floatFromInt(@as(usize, @intFromFloat(requested_count)))) != requested_count) return -1;
    const count: usize = @intFromFloat(requested_count);
    if (input_length != 6 + 4 * count) return -1;
    var query: [3]f64 = undefined;
    for (0..3) |axis| { query[axis] = input[3 + axis]; if (!(query[axis] >= -32.0 and query[axis] <= 32.0)) return -1; }
    var ctx = Context{};
    var minima: [3]f64 = @splat(32.0);
    var maxima: [3]f64 = @splat(-32.0);
    for (0..count) |body| {
        for (0..3) |axis| {
            const value = input[6 + 4 * body + axis];
            if (!(value >= -32.0 and value <= 32.0)) return -1;
            if (@as(f64, @floatFromInt(@as(i64, @intFromFloat(value)))) != value) return -1;
            ctx.bodies[body].position[axis] = value;
            minima[axis] = @min(minima[axis], value);
            maxima[axis] = @max(maxima[axis], value);
        }
        const mass = input[9 + 4 * body];
        if (!(mass >= 1.0 and mass <= 16.0)) return -1;
        ctx.bodies[body].mass = mass;
    }
    for (0..count) |a| {
        for (a + 1..count) |b| {
            if (ctx.bodies[a].position[0] == ctx.bodies[b].position[0] and ctx.bodies[a].position[1] == ctx.bodies[b].position[1] and ctx.bodies[a].position[2] == ctx.bodies[b].position[2]) return -1;
        }
    }
    var inside = true;
    for (0..3) |axis| if (query[axis] < minima[axis] or query[axis] > maxima[axis]) { inside = false; };
    if (inside) return -1;
    if (output == null or output_capacity < 4) return -2;
    const side = @max(maxima[0] - minima[0], @max(maxima[1] - minima[1], maxima[2] - minima[2]));
    if (side <= 0.0) return -1;
    var center: [3]f64 = undefined;
    for (0..3) |axis| center[axis] = (minima[axis] + maxima[axis]) / 2.0;
    const root = newCell(&ctx) orelse return -1;
    for (0..count) |body| if (!insertBody(&ctx, root, body, center, side / 2.0, 0)) return -1;
    aggregate(&ctx, root);
    var potential: f64 = 0.0;
    var acceleration: [3]f64 = @splat(0.0);
    walk(&ctx, root, side, theta * theta, query, softening * softening, &potential, &acceleration);
    output[0] = potential; output[1] = acceleration[0]; output[2] = acceleration[1]; output[3] = acceleration[2];
    return 4;
}
