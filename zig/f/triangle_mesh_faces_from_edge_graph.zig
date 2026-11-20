const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_TRIANGLES: usize = 56;
const MAX_INPUT_WORDS: usize = 59;
const MAX_OUTPUT_WORDS: usize = 170;

const Triangle = struct {
    a: usize,
    b: usize,
    c: usize,
    e0: usize,
    e1: usize,
    e2: usize,
    active: bool,
};

fn selectTriangle(chosen: usize, triangles: *[MAX_TRIANGLES]Triangle,
    triangle_count: usize, incidence: *[MAX_EDGES]i32,
    used: *[MAX_EDGES]i32, staged: *[MAX_OUTPUT_WORDS]i64,
    face_count: *usize) void {
    const t = triangles[chosen];
    triangles[chosen].active = false;
    staged[2 + 3 * face_count.*] = @intCast(t.a);
    staged[3 + 3 * face_count.*] = @intCast(t.b);
    staged[4 + 3 * face_count.*] = @intCast(t.c);
    face_count.* += 1;

    const face_edges = [_]usize{ t.e0, t.e1, t.e2 };
    var saturated = [_]bool{false} ** MAX_EDGES;
    for (face_edges) |edge| {
        incidence[edge] -= 1;
        used[edge] += 1;
        if (used[edge] == 2) saturated[edge] = true;
    }
    for (0..triangle_count) |other| {
        if (!triangles[other].active) continue;
        const candidate = triangles[other];
        if (saturated[candidate.e0] or saturated[candidate.e1] or saturated[candidate.e2]) {
            triangles[other].active = false;
            incidence[candidate.e0] -= 1;
            incidence[candidate.e1] -= 1;
            incidence[candidate.e2] -= 1;
        }
    }
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn triangle_mesh_faces_from_edge_graph(raw: ?[*]const i64,
    length: usize, output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 2 or length > MAX_INPUT_WORDS) return -1;
    const vertex_word = input[0];
    const edge_word = input[1];
    if (vertex_word < 3 or vertex_word > MAX_VERTICES or edge_word < 0 or edge_word > MAX_EDGES) return -1;
    const vertices: usize = @intCast(vertex_word);
    const edge_count: usize = @intCast(edge_word);
    if (edge_count > vertices * (vertices - 1) / 2 or length != 2 + 2 * edge_count) return -1;

    var edge_index = [_][MAX_VERTICES]i32{[_]i32{-1} ** MAX_VERTICES} ** MAX_VERTICES;
    var vertex_degree = [_]i32{0} ** MAX_VERTICES;
    for (0..edge_count) |edge| {
        const left_word = input[2 + 2 * edge];
        const right_word = input[3 + 2 * edge];
        if (left_word < 0 or left_word >= vertex_word or right_word < 0 or right_word >= vertex_word or left_word == right_word) return -1;
        var left: usize = @intCast(left_word);
        var right: usize = @intCast(right_word);
        if (left > right) { const swap = left; left = right; right = swap; }
        if (edge_index[left][right] >= 0) return -1;
        edge_index[left][right] = @intCast(edge);
        edge_index[right][left] = @intCast(edge);
        vertex_degree[left] += 1;
        vertex_degree[right] += 1;
    }

    var triangles = [_]Triangle{.{ .a = 0, .b = 0, .c = 0, .e0 = 0, .e1 = 0, .e2 = 0, .active = false }} ** MAX_TRIANGLES;
    var triangle_count: usize = 0;
    var incidence = [_]i32{0} ** MAX_EDGES;
    for (0..vertices) |a| {
        for (a + 1..vertices) |b| {
            for (b + 1..vertices) |c| {
                const e0 = edge_index[a][b];
                const e1 = edge_index[a][c];
                const e2 = edge_index[b][c];
                if (e0 >= 0 and e1 >= 0 and e2 >= 0) {
                    triangles[triangle_count] = .{ .a = a, .b = b, .c = c, .e0 = @intCast(e0), .e1 = @intCast(e1), .e2 = @intCast(e2), .active = true };
                    triangle_count += 1;
                    incidence[@intCast(e0)] += 1;
                    incidence[@intCast(e1)] += 1;
                    incidence[@intCast(e2)] += 1;
                }
            }
        }
    }

    var used = [_]i32{0} ** MAX_EDGES;
    var staged = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var face_count: usize = 0;
    var fallback_used = false;
    while (true) {
        var chosen = triangle_count;
        for (0..triangle_count) |index| {
            const t = triangles[index];
            if (t.active and (vertex_degree[t.a] == 3 or vertex_degree[t.b] == 3 or vertex_degree[t.c] == 3)) { chosen = index; break; }
        }
        if (chosen < triangle_count) {
            selectTriangle(chosen, &triangles, triangle_count, &incidence, &used, &staged, &face_count);
            continue;
        }

        var forced = [_]bool{false} ** MAX_EDGES;
        for (0..edge_count) |edge| forced[edge] = incidence[edge] > 0 and incidence[edge] == 2 - used[edge];
        chosen = triangle_count;
        for (0..triangle_count) |index| {
            const t = triangles[index];
            if (t.active and (forced[t.e0] or forced[t.e1] or forced[t.e2])) { chosen = index; break; }
        }
        if (chosen < triangle_count) {
            selectTriangle(chosen, &triangles, triangle_count, &incidence, &used, &staged, &face_count);
            continue;
        }

        var best_score: i32 = 3 * @as(i32, @intCast(MAX_TRIANGLES)) + 1;
        chosen = triangle_count;
        for (0..triangle_count) |index| {
            const t = triangles[index];
            if (!t.active) continue;
            const score = incidence[t.e0] + incidence[t.e1] + incidence[t.e2];
            if (score < best_score) { best_score = score; chosen = index; }
        }
        if (chosen == triangle_count) break;
        fallback_used = true;
        selectTriangle(chosen, &triangles, triangle_count, &incidence, &used, &staged, &face_count);
    }

    var complete = edge_count > 0;
    for (0..edge_count) |edge| if (used[edge] != 2) { complete = false; };
    staged[0] = (if (complete) @as(i64, 0) else 2) + @as(i64, @intFromBool(fallback_used));
    staged[1] = @intCast(face_count);
    const output_bytes = (2 + 3 * face_count) * 8;
    const destination = output orelse return -2;
    if (capacity < output_bytes) return -2;
    for (0..2 + 3 * face_count) |word| storeI64Le(destination, word * 8, staged[word]);
    return @intCast(output_bytes);
}
