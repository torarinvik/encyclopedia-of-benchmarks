const MAX_N: usize = 12;
const MAX_M: usize = 60;
const MAX_P: usize = 119;
const MAX_B: usize = 12;
const MAX_BLOCKS: usize = 44;
const MAX_INPUT: usize = 2088;
const INF: i64 = 1152921504606846976;

const Arc = struct { tail: usize, head: usize, weight: i64 };
const Piece = struct {
    left: i32 = -1,
    right: i32 = -1,
    boundary_count: usize = 0,
    arc_mask: u64 = 0,
    vertex_mask: u16 = 0,
    boundary: [MAX_B]usize = [_]usize{0} ** MAX_B,
};
const Block = struct {
    child: usize = 0,
    row_count: usize = 0,
    column_count: usize = 0,
    rows: [MAX_B]usize = [_]usize{0} ** MAX_B,
    columns: [MAX_B]usize = [_]usize{0} ** MAX_B,
    weights: [MAX_B][MAX_B]i64 = [_][MAX_B]i64{[_]i64{INF} ** MAX_B} ** MAX_B,
    best_value: [MAX_B]i64 = [_]i64{INF} ** MAX_B,
    best_row: [MAX_B]i32 = [_]i32{-1} ** MAX_B,
};
const Context = struct {
    n: usize = 0,
    m: usize = 0,
    source: usize = 0,
    piece_count: usize = 0,
    pieces: [MAX_P]Piece = [_]Piece{.{}} ** MAX_P,
    arcs: [MAX_M]Arc = [_]Arc{.{ .tail = 0, .head = 0, .weight = 0 }} ** MAX_M,
    ddg: [MAX_P][MAX_N][MAX_N]i64 = [_][MAX_N][MAX_N]i64{[_][MAX_N]i64{[_]i64{INF} ** MAX_N} ** MAX_N} ** MAX_P,
    potentials: [MAX_P][MAX_N]i64 = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_P,
};

fn pop16(value_in: u16) usize {
    var value = value_in;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += @intCast(value & 1);
    return count;
}

fn vertexMask(ctx: *const Context, mask: u64) u16 {
    var result: u16 = 0;
    for (0..ctx.m) |edge| if ((mask & (@as(u64, 1) << @intCast(edge))) != 0) {
        result |= @as(u16, 1) << @intCast(ctx.arcs[edge].tail);
        result |= @as(u16, 1) << @intCast(ctx.arcs[edge].head);
    };
    return result;
}

fn connected(ctx: *const Context, mask: u64, vertices: u16) bool {
    if (vertices == 0) return false;
    const start: usize = @intCast(@ctz(vertices));
    var reached: u16 = @as(u16, 1) << @intCast(start);
    var changed = true;
    while (changed) {
        changed = false;
        for (0..ctx.m) |edge| {
            if ((mask & (@as(u64, 1) << @intCast(edge))) == 0) continue;
            const u = ctx.arcs[edge].tail;
            const v = ctx.arcs[edge].head;
            const ub = @as(u16, 1) << @intCast(u);
            const vb = @as(u16, 1) << @intCast(v);
            if ((reached & ub) != 0 and (reached & vb) == 0) { reached |= vb; changed = true; }
            if ((reached & vb) != 0 and (reached & ub) == 0) { reached |= ub; changed = true; }
        }
    }
    return reached == vertices;
}

fn parse(ctx: *Context, input: [*c]const i64, length: usize) bool {
    if (input == null or length < 4 or length > MAX_INPUT) return false;
    if (input[0] < 2 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M)) or
        input[2] < 0 or input[2] >= input[0] or input[3] < 1 or input[3] > @as(i64, @intCast(MAX_P)) or input[3] % 2 == 0) return false;
    ctx.n = @intCast(input[0]); ctx.m = @intCast(input[1]); ctx.source = @intCast(input[2]); ctx.piece_count = @intCast(input[3]);
    var seen_arc = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var seen_pair = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var pair_count: usize = 0;
    var offset: usize = 4;
    for (0..ctx.m) |edge| {
        if (offset + 3 > length) return false;
        const u0 = input[offset]; const v0 = input[offset + 1]; const w = input[offset + 2]; offset += 3;
        if (u0 < 0 or u0 >= @as(i64, @intCast(ctx.n)) or v0 < 0 or v0 >= @as(i64, @intCast(ctx.n)) or u0 == v0 or w < -100 or w > 100) return false;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        if (seen_arc[u][v]) return false;
        seen_arc[u][v] = true;
        if (!seen_pair[u][v]) { seen_pair[u][v] = true; seen_pair[v][u] = true; pair_count += 1; }
        ctx.arcs[edge] = .{ .tail = u, .head = v, .weight = w };
    }
    const edge_limit = if (ctx.n == 2) @as(usize, 1) else 3 * ctx.n - 6;
    if (pair_count > edge_limit or ctx.m > 2 * edge_limit) return false;
    var reached: u16 = 1;
    var changed = true;
    while (changed) {
        changed = false;
        for (0..ctx.m) |edge| {
            const u = ctx.arcs[edge].tail; const v = ctx.arcs[edge].head;
            const ub = @as(u16, 1) << @intCast(u); const vb = @as(u16, 1) << @intCast(v);
            if ((reached & ub) != 0 and (reached & vb) == 0) { reached |= vb; changed = true; }
            if ((reached & vb) != 0 and (reached & ub) == 0) { reached |= ub; changed = true; }
        }
    }
    if (reached != (@as(u16, 1) << @intCast(ctx.n)) - 1) return false;

    var parents = [_]u8{0} ** MAX_P;
    var leaf_union: u64 = 0; var leaf_count: usize = 0;
    const full = (@as(u64, 1) << @intCast(ctx.m)) - 1;
    for (0..ctx.piece_count) |index| {
        if (offset + 4 > length) return false;
        const left = input[offset]; const right = input[offset + 1]; const mask_value = input[offset + 2]; const bc0 = input[offset + 3]; offset += 4;
        if (bc0 < 1 or bc0 > @as(i64, @intCast(ctx.n)) or bc0 > @as(i64, @intCast(MAX_B)) or offset + @as(usize, @intCast(bc0)) > length) return false;
        var piece = Piece{}; piece.left = @intCast(left); piece.right = @intCast(right); piece.boundary_count = @intCast(bc0);
        var listed: u16 = 0;
        for (0..piece.boundary_count) |j| {
            const v0 = input[offset]; offset += 1;
            if (v0 < 0 or v0 >= ctx.n) return false;
            const v: usize = @intCast(v0); const bit = @as(u16, 1) << @intCast(v);
            if ((listed & bit) != 0) return false;
            listed |= bit; piece.boundary[j] = v;
        }
        if (left == -1 and right == -1) {
            if (mask_value <= 0) return false;
            piece.arc_mask = @intCast(mask_value);
            if ((piece.arc_mask & ~full) != 0 or @popCount(piece.arc_mask) > 3 or (leaf_union & piece.arc_mask) != 0) return false;
            leaf_union |= piece.arc_mask; leaf_count += 1; piece.vertex_mask = vertexMask(ctx, piece.arc_mask);
            if (!connected(ctx, piece.arc_mask, piece.vertex_mask)) return false;
        } else {
            if (left < 0 or right < 0 or left >= @as(i64, @intCast(index)) or right >= @as(i64, @intCast(index)) or left == right or mask_value != -1) return false;
            const li: usize = @intCast(left); const ri: usize = @intCast(right);
            if (parents[li] != 0 or parents[ri] != 0) return false;
            parents[li] = 1; parents[ri] = 1;
            const lp = ctx.pieces[li]; const rp = ctx.pieces[ri];
            if ((lp.arc_mask & rp.arc_mask) != 0) return false;
            piece.arc_mask = lp.arc_mask | rp.arc_mask; piece.vertex_mask = lp.vertex_mask | rp.vertex_mask;
            const psize = pop16(piece.vertex_mask); const limit = (2 * psize + 2) / 3;
            if (pop16(lp.vertex_mask) > limit or pop16(rp.vertex_mask) > limit or (lp.vertex_mask & rp.vertex_mask) == 0) return false;
        }
        var expected: u16 = 0;
        for (0..ctx.n) |v| {
            const bit = @as(u16, 1) << @intCast(v);
            if ((piece.vertex_mask & bit) == 0) continue;
            if (v == ctx.source) { expected |= bit; continue; }
            for (0..ctx.m) |edge| {
                if ((piece.arc_mask & (@as(u64, 1) << @intCast(edge))) == 0 and (ctx.arcs[edge].tail == v or ctx.arcs[edge].head == v)) { expected |= bit; break; }
            }
        }
        if (listed != expected or !connected(ctx, piece.arc_mask, piece.vertex_mask)) return false;
        if (index + 1 == ctx.piece_count and (piece.arc_mask != full or piece.vertex_mask != (@as(u16, 1) << @intCast(ctx.n)) - 1)) return false;
        ctx.pieces[index] = piece;
    }
    if (offset != length or ctx.piece_count != 2 * leaf_count - 1 or leaf_union != full or parents[ctx.piece_count - 1] != 0) return false;
    for (0..ctx.piece_count - 1) |i| if (parents[i] != 1) return false;
    const root = ctx.pieces[ctx.piece_count - 1];
    return root.boundary_count == 1 and root.boundary[0] == ctx.source;
}

fn bellman(ctx: *const Context, nodes: []const usize, arcs: []const Arc, labels: *[MAX_N]i64) bool {
    for (0..ctx.n) |v| labels[v] = INF;
    for (nodes) |v| labels[v] = 0;
    for (0..nodes.len -| 1) |_| {
        var changed = false;
        for (arcs) |arc| if (labels[arc.tail] + arc.weight < labels[arc.head]) { labels[arc.head] = labels[arc.tail] + arc.weight; changed = true; };
        if (!changed) break;
    }
    for (arcs) |arc| if (labels[arc.tail] + arc.weight < labels[arc.head]) return false;
    return true;
}

fn seeded(ctx: *const Context, arcs: []const Arc, seeds: *const [MAX_N]i64, labels: *[MAX_N]i64) bool {
    for (0..ctx.n) |v| labels[v] = seeds[v];
    for (0..ctx.n - 1) |_| {
        var changed = false;
        for (arcs) |arc| if (labels[arc.tail] != INF and labels[arc.tail] + arc.weight < labels[arc.head]) { labels[arc.head] = labels[arc.tail] + arc.weight; changed = true; };
        if (!changed) break;
    }
    for (arcs) |arc| if (labels[arc.tail] != INF and labels[arc.tail] + arc.weight < labels[arc.head]) return false;
    return true;
}

fn monge(ctx: *const Context, index: usize, lo: usize, hi: usize) bool {
    if (hi - lo <= 1) return true;
    const middle = (lo + hi) / 2; const piece = ctx.pieces[index];
    for (0..2) |direction| {
        const rlo = if (direction == 0) lo else middle; const rhi = if (direction == 0) middle else hi;
        const clo = if (direction == 0) middle else lo; const chi = if (direction == 0) hi else middle;
        var i = rlo; while (i < rhi) : (i += 1) { var i2 = i + 1; while (i2 < rhi) : (i2 += 1) {
            var j = clo; while (j < chi) : (j += 1) { var j2 = j + 1; while (j2 < chi) : (j2 += 1) {
                const u = piece.boundary[i]; const u2 = piece.boundary[i2]; const v = piece.boundary[j]; const v2 = piece.boundary[j2];
                const a = ctx.ddg[index][u][v]; const b = ctx.ddg[index][u2][v2]; const c = ctx.ddg[index][u][v2]; const d = ctx.ddg[index][u2][v];
                const lhs = if (a == INF or b == INF) INF else a + b; const rhs = if (c == INF or d == INF) INF else c + d;
                if (lhs > rhs) return false;
            }}
        }}
    }
    return monge(ctx, index, lo, middle) and monge(ctx, index, middle, hi);
}

fn addBlock(ctx: *const Context, child: usize, rows: []const usize, cols: []const usize, potential: *const [MAX_N]i64, blocks: *[MAX_BLOCKS]Block, count: *usize) void {
    if (rows.len == 0 or cols.len == 0 or count.* >= MAX_BLOCKS) return;
    var block = Block{}; block.child = child; block.row_count = rows.len; block.column_count = cols.len;
    for (rows, 0..) |v, i| block.rows[i] = v;
    for (cols, 0..) |v, j| block.columns[j] = v;
    for (rows, 0..) |u, i| for (cols, 0..) |v, j| {
        const d = ctx.ddg[child][u][v];
        block.weights[i][j] = if (d == INF) INF else d + potential[u] - potential[v];
    };
    blocks[count.*] = block; count.* += 1;
}

fn buildBlocksRec(ctx: *const Context, child: usize, lo: usize, hi: usize, potential: *const [MAX_N]i64, blocks: *[MAX_BLOCKS]Block, count: *usize) void {
    if (hi - lo <= 1) return;
    const piece = ctx.pieces[child]; const middle = (lo + hi) / 2;
    addBlock(ctx, child, piece.boundary[lo..middle], piece.boundary[middle..hi], potential, blocks, count);
    addBlock(ctx, child, piece.boundary[middle..hi], piece.boundary[lo..middle], potential, blocks, count);
    buildBlocksRec(ctx, child, lo, middle, potential, blocks, count);
    buildBlocksRec(ctx, child, middle, hi, potential, blocks, count);
}

fn activate(vertex: usize, value: i64, blocks: *[MAX_BLOCKS]Block, count: usize, settled: *const [MAX_N]bool) void {
    for (0..count) |bi| { var block = &blocks[bi]; for (0..block.row_count) |i| if (block.rows[i] == vertex) {
        for (0..block.column_count) |j| {
            const target = block.columns[j]; const weight = block.weights[i][j];
            if (settled[target] or weight == INF) continue;
            const candidate = value + weight;
            if (candidate < block.best_value[j] or (candidate == block.best_value[j] and @as(i32, @intCast(vertex)) < block.best_row[j])) {
                block.best_value[j] = candidate; block.best_row[j] = @intCast(vertex);
            }
        }
    }; }
}

fn settle(vertex: usize, settled: *[MAX_N]bool, blocks: *[MAX_BLOCKS]Block, count: usize) void {
    settled[vertex] = true;
    for (0..count) |bi| { for (0..blocks[bi].column_count) |j| if (blocks[bi].columns[j] == vertex) { blocks[bi].best_value[j] = INF; blocks[bi].best_row[j] = -1; }; }
}

fn dijkstra(ctx: *const Context, nodes: []const usize, blocks: *[MAX_BLOCKS]Block, count: usize, seeds: *const [MAX_N]i64, labels: *[MAX_N]i64) void {
    var settled: [MAX_N]bool = [_]bool{false} ** MAX_N;
    for (0..ctx.n) |v| labels[v] = INF;
    for (0..count) |bi| for (0..blocks[bi].column_count) |j| { blocks[bi].best_value[j] = INF; blocks[bi].best_row[j] = -1; };
    for (nodes) |v| if (seeds[v] < labels[v]) { labels[v] = seeds[v]; };
    for (nodes) |v| if (labels[v] != INF) activate(v, labels[v], blocks, count, &settled);
    while (true) {
        var best_vertex: ?usize = null; var best_value = INF; var best_row: i32 = 2147483647;
        for (nodes) |v| if (!settled[v] and labels[v] != INF) {
            if (labels[v] < best_value or (labels[v] == best_value and (best_vertex == null or v < best_vertex.?))) { best_vertex = v; best_value = labels[v]; best_row = -1; }
        };
        for (0..count) |bi| for (0..blocks[bi].column_count) |j| {
            const v = blocks[bi].columns[j]; const candidate = blocks[bi].best_value[j]; const row = blocks[bi].best_row[j];
            if (settled[v] or candidate == INF) continue;
            if (candidate < best_value or (candidate == best_value and (best_vertex == null or v < best_vertex.?)) or (candidate == best_value and best_vertex.? == v and row < best_row)) {
                best_vertex = v; best_value = candidate; best_row = row;
            }
        };
        if (best_vertex == null) break;
        const v = best_vertex.?; if (best_value < labels[v]) labels[v] = best_value;
        settle(v, &settled, blocks, count); activate(v, labels[v], blocks, count, &settled);
    }
}

fn buildPiece(ctx: *Context, index: usize, blocks: *[MAX_BLOCKS]Block) bool {
    const piece = ctx.pieces[index];
    for (0..ctx.n) |u| for (0..ctx.n) |v| { ctx.ddg[index][u][v] = INF; };
    if (piece.left == -1) {
        var arcs: [3]Arc = undefined; var arc_count: usize = 0; var nodes: [MAX_N]usize = undefined; var node_count: usize = 0;
        for (0..ctx.m) |e| if ((piece.arc_mask & (@as(u64, 1) << @intCast(e))) != 0) { arcs[arc_count] = ctx.arcs[e]; arc_count += 1; };
        for (0..ctx.n) |v| if ((piece.vertex_mask & (@as(u16, 1) << @intCast(v))) != 0) { nodes[node_count] = v; node_count += 1; };
        var potential = [_]i64{0} ** MAX_N; if (!bellman(ctx, nodes[0..node_count], arcs[0..arc_count], &potential)) return false;
        for (0..piece.boundary_count) |i| {
            var seeds = [_]i64{INF} ** MAX_N; var labels: [MAX_N]i64 = undefined; seeds[piece.boundary[i]] = 0;
            if (!seeded(ctx, arcs[0..arc_count], &seeds, &labels)) return false;
            for (0..piece.boundary_count) |j| ctx.ddg[index][piece.boundary[i]][piece.boundary[j]] = labels[piece.boundary[j]];
        }
        return true;
    }
    const left: usize = @intCast(piece.left); const right: usize = @intCast(piece.right);
    var present = [_]bool{false} ** MAX_N; for (0..ctx.pieces[left].boundary_count) |i| present[ctx.pieces[left].boundary[i]] = true; for (0..ctx.pieces[right].boundary_count) |i| present[ctx.pieces[right].boundary[i]] = true;
    var nodes: [MAX_N]usize = undefined; var node_count: usize = 0; for (0..ctx.n) |v| if (present[v]) { nodes[node_count] = v; node_count += 1; };
    var union_arcs: [2 * MAX_B * MAX_B]Arc = undefined; var union_count: usize = 0;
    for ([2]usize{ left, right }) |child| for (0..ctx.pieces[child].boundary_count) |i| for (0..ctx.pieces[child].boundary_count) |j| {
        const u = ctx.pieces[child].boundary[i]; const v = ctx.pieces[child].boundary[j]; const d = ctx.ddg[child][u][v];
        if (u != v and d != INF) { union_arcs[union_count] = .{ .tail = u, .head = v, .weight = d }; union_count += 1; }
    };
    var potential = [_]i64{0} ** MAX_N; if (!bellman(ctx, nodes[0..node_count], union_arcs[0..union_count], &potential)) return false; ctx.potentials[index] = potential;
    for (0..union_count) |e| if (union_arcs[e].weight + potential[union_arcs[e].tail] - potential[union_arcs[e].head] < 0) return false;
    var count: usize = 0;
    for ([2]usize{ left, right }) |child| {
        if (!monge(ctx, child, 0, ctx.pieces[child].boundary_count)) return false;
        buildBlocksRec(ctx, child, 0, ctx.pieces[child].boundary_count, &potential, blocks, &count);
    }
    if (count > MAX_BLOCKS) return false;
    for (0..piece.boundary_count) |i| {
        var seeds = [_]i64{INF} ** MAX_N; var labels: [MAX_N]i64 = undefined; seeds[piece.boundary[i]] = 0;
        dijkstra(ctx, nodes[0..node_count], blocks, count, &seeds, &labels);
        for (0..piece.boundary_count) |j| { const source = piece.boundary[i]; const target = piece.boundary[j]; ctx.ddg[index][source][target] = if (labels[target] == INF) INF else labels[target] - potential[source] + potential[target]; }
    }
    return true;
}

fn expand(ctx: *Context, index: usize, known: *const [MAX_N]i64, result: *[MAX_N]i64, blocks: *[MAX_BLOCKS]Block) void {
    const piece = ctx.pieces[index];
    if (piece.left == -1) {
        var arcs: [3]Arc = undefined; var count: usize = 0;
        for (0..ctx.m) |e| if ((piece.arc_mask & (@as(u64, 1) << @intCast(e))) != 0) { arcs[count] = ctx.arcs[e]; count += 1; };
        var labels: [MAX_N]i64 = undefined; if (!seeded(ctx, arcs[0..count], known, &labels)) return;
        for (0..ctx.n) |v| if ((piece.vertex_mask & (@as(u16, 1) << @intCast(v))) != 0 and labels[v] < result[v]) { result[v] = labels[v]; };
        return;
    }
    const left: usize = @intCast(piece.left); const right: usize = @intCast(piece.right); const parent_potential = &ctx.potentials[index];
    var present = [_]bool{false} ** MAX_N; for (0..ctx.pieces[left].boundary_count) |i| present[ctx.pieces[left].boundary[i]] = true; for (0..ctx.pieces[right].boundary_count) |i| present[ctx.pieces[right].boundary[i]] = true;
    var nodes: [MAX_N]usize = undefined; var node_count: usize = 0; for (0..ctx.n) |v| if (present[v]) { nodes[node_count] = v; node_count += 1; };
    var count: usize = 0; buildBlocksRec(ctx, left, 0, ctx.pieces[left].boundary_count, parent_potential, blocks, &count); buildBlocksRec(ctx, right, 0, ctx.pieces[right].boundary_count, parent_potential, blocks, &count);
    var seeds = [_]i64{INF} ** MAX_N; for (0..piece.boundary_count) |i| { const v = piece.boundary[i]; if (known[v] != INF) seeds[v] = known[v] - parent_potential[v]; }
    var reduced: [MAX_N]i64 = undefined; dijkstra(ctx, nodes[0..node_count], blocks, count, &seeds, &reduced);
    var raw = [_]i64{INF} ** MAX_N; for (0..ctx.n) |v| if (reduced[v] != INF) { raw[v] = reduced[v] + parent_potential[v]; };
    for ([_]usize{left, right}) |child| {
        var child_known = [_]i64{INF} ** MAX_N; for (0..ctx.pieces[child].boundary_count) |i| { const v = ctx.pieces[child].boundary[i]; child_known[v] = raw[v]; }
        expand(ctx, child, &child_known, result, blocks);
    }
}

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn fakcharoenphol_rao_planar_sssp(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    var ctx = Context{};
    if (!parse(&ctx, input, length)) return -1;
    var all_nodes: [MAX_N]usize = undefined; for (0..ctx.n) |v| all_nodes[v] = v;
    var potential = [_]i64{0} ** MAX_N;
    if (!bellman(&ctx, all_nodes[0..ctx.n], ctx.arcs[0..ctx.m], &potential)) return -1;
    var blocks: [MAX_BLOCKS]Block = [_]Block{.{}} ** MAX_BLOCKS;
    for (0..ctx.piece_count) |p| if (!buildPiece(&ctx, p, &blocks)) return -1;
    var result = [_]i64{INF} ** MAX_N; var known = [_]i64{INF} ** MAX_N; known[ctx.source] = 0;
    expand(&ctx, ctx.piece_count - 1, &known, &result, &blocks);
    const required = ctx.n * 8;
    if (output == null or capacity < required) return -2;
    for (0..ctx.n) |v| putI64(output, v * 8, if (result[v] == INF) 9223372036854775807 else result[v]);
    return @intCast(required);
}
