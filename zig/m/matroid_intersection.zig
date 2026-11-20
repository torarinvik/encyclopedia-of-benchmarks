const MAX_VERTICES: usize = 10;
const MAX_EDGES: usize = 20;
const MAX_COLORS: usize = 8;

fn isForest(input: [*c]const i64, vertices: usize, edges: usize, edge_start: usize,
            chosen: *const [MAX_EDGES]bool, removed: i64, added: i64) bool {
    var parent: [MAX_VERTICES]i64 = @splat(0);
    for (0..vertices) |vertex| parent[vertex] = @intCast(vertex);
    for (0..edges) |edge| {
        if (@as(i64, @intCast(edge)) != added and (!chosen[0][edge] or @as(i64, @intCast(edge)) == removed)) continue;
        var a: usize = @intCast(input[edge_start + 3 * edge]);
        var b: usize = @intCast(input[edge_start + 3 * edge + 1]);
        while (parent[a] != @as(i64, @intCast(a))) a = @intCast(parent[a]);
        while (parent[b] != @as(i64, @intCast(b))) b = @intCast(parent[b]);
        if (a == b) return false;
        parent[b] = @intCast(a);
    }
    return true;
}

fn withinQuotas(input: [*c]const i64, colors: usize, edges: usize, edge_start: usize,
                chosen: *const [MAX_EDGES]bool, removed: i64, added: i64) bool {
    var counts: [MAX_COLORS]i64 = @splat(0);
    for (0..edges) |edge| {
        if (@as(i64, @intCast(edge)) != added and (!chosen[0][edge] or @as(i64, @intCast(edge)) == removed)) continue;
        const color: usize = @intCast(input[edge_start + 3 * edge + 2]);
        counts[color] += 1;
        if (counts[color] > input[3 + color]) return false;
    }
    return true;
}

pub export fn matroid_intersection(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 72) return -1;
    const vertices_value = input[0];
    const edges_value = input[1];
    const colors_value = input[2];
    if (vertices_value < 1 or vertices_value > MAX_VERTICES or edges_value < 0 or edges_value > MAX_EDGES
        or colors_value < 1 or colors_value > MAX_COLORS) return -1;
    const vertices: usize = @intCast(vertices_value);
    const edges: usize = @intCast(edges_value);
    const colors: usize = @intCast(colors_value);
    if (length != 3 + colors + 3 * edges) return -1;
    for (0..colors) |color| {
        if (input[3 + color] < 0 or input[3 + color] > MAX_EDGES) return -1;
    }
    const edge_start = 3 + colors;
    for (0..edges) |edge| {
        const u = input[edge_start + 3 * edge];
        const v = input[edge_start + 3 * edge + 1];
        const color = input[edge_start + 3 * edge + 2];
        if (u < 0 or u >= vertices_value or v < 0 or v >= vertices_value
            or color < 0 or color >= colors_value) return -1;
    }

    var chosen: [MAX_EDGES]bool = @splat(false);
    while (true) {
        var predecessor: [MAX_EDGES]i64 = @splat(-2);
        var queue: [MAX_EDGES]i64 = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        for (0..edges) |edge| {
            if (!chosen[edge] and isForest(input, vertices, edges, edge_start, &chosen, -1, @intCast(edge))) {
                predecessor[edge] = -1;
                queue[tail] = @intCast(edge);
                tail += 1;
            }
        }
        var terminal: i64 = -1;
        while (head < tail and terminal < 0) {
            const current: usize = @intCast(queue[head]);
            head += 1;
            if (!chosen[current]) {
                if (withinQuotas(input, colors, edges, edge_start, &chosen, -1, @intCast(current))) {
                    terminal = @intCast(current);
                    break;
                }
                for (0..edges) |inside| {
                    if (chosen[inside] and predecessor[inside] == -2
                        and withinQuotas(input, colors, edges, edge_start, &chosen,
                                         @intCast(inside), @intCast(current))) {
                        predecessor[inside] = @intCast(current);
                        queue[tail] = @intCast(inside);
                        tail += 1;
                    }
                }
            } else {
                for (0..edges) |outside| {
                    if (!chosen[outside] and predecessor[outside] == -2
                        and isForest(input, vertices, edges, edge_start, &chosen,
                                     @intCast(current), @intCast(outside))) {
                        predecessor[outside] = @intCast(current);
                        queue[tail] = @intCast(outside);
                        tail += 1;
                    }
                }
            }
        }
        if (terminal < 0) break;
        var node = terminal;
        while (node >= 0) {
            const edge: usize = @intCast(node);
            chosen[edge] = !chosen[edge];
            node = predecessor[edge];
        }
    }
    var answer: i64 = 0;
    for (0..edges) |edge| {
        if (chosen[edge]) answer += 1;
    }
    return answer;
}
