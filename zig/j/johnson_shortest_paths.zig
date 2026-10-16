const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 770;
const MAX_QUEUE: usize = MAX_EDGES + 1;
const UNREACHABLE_SENTINEL: i64 = 1 << 62;
const FNV_OFFSET_BASIS: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn fnvWord(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        hash ^= (bits >> @intCast(8 * byte)) & 0xff;
        hash *%= FNV_PRIME;
    }
    return hash;
}

export fn johnson_shortest_paths(input_pointer: ?[*]const i64, length: usize) i64 {
    const input = input_pointer orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_value = input[0];
    const edge_value = input[1];
    if (vertex_value < 1 or vertex_value > MAX_VERTICES or edge_value < 0 or edge_value > MAX_EDGES) return -1;
    const vertices: usize = @intCast(vertex_value);
    const edges: usize = @intCast(edge_value);
    if (length != 2 + 3 * edges) return -1;

    var edge_from: [MAX_EDGES]usize = undefined;
    var edge_to: [MAX_EDGES]usize = undefined;
    var edge_weight: [MAX_EDGES]i64 = undefined;
    for (0..edges) |edge| {
        const from = input[2 + 3 * edge];
        const to = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (from < 1 or from > vertex_value or to < 1 or to > vertex_value or weight < -32 or weight > 32) return -1;
        edge_from[edge] = @intCast(from - 1);
        edge_to[edge] = @intCast(to - 1);
        edge_weight[edge] = weight;
    }

    var potential = [_]i64{0} ** MAX_VERTICES;
    for (1..vertices) |_| {
        var updated = false;
        for (0..edges) |edge| {
            const from = edge_from[edge];
            const to = edge_to[edge];
            const candidate = potential[from] + edge_weight[edge];
            if (candidate < potential[to]) {
                potential[to] = candidate;
                updated = true;
            }
        }
        if (!updated) break;
    }
    for (0..edges) |edge| {
        if (potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]]) return -1;
    }

    var result = FNV_OFFSET_BASIS;
    for (0..vertices) |source| {
        var distance = [_]i64{std.math.maxInt(i64)} ** MAX_VERTICES;
        var visited = [_]bool{false} ** MAX_VERTICES;
        distance[source] = 0;
        var queue_vertices: [MAX_QUEUE]usize = undefined;
        var queue_distances: [MAX_QUEUE]i64 = undefined;
        var queue_length: usize = 1;
        queue_vertices[0] = source;
        queue_distances[0] = 0;
        while (queue_length > 0) {
            var minimum: usize = 0;
            for (1..queue_length) |index| {
                if (queue_distances[index] < queue_distances[minimum]) minimum = index;
            }
            const current = queue_vertices[minimum];
            for (minimum + 1..queue_length) |index| {
                queue_vertices[index - 1] = queue_vertices[index];
                queue_distances[index - 1] = queue_distances[index];
            }
            queue_length -= 1;
            if (visited[current]) continue;
            visited[current] = true;

            for (0..edges) |edge| {
                if (edge_from[edge] != current) continue;
                const next = edge_to[edge];
                const reweighted = edge_weight[edge] + potential[current] - potential[next];
                const candidate = distance[current] + reweighted;
                if (!visited[next] and candidate < distance[next]) {
                    distance[next] = candidate;
                    queue_vertices[queue_length] = next;
                    queue_distances[queue_length] = candidate;
                    queue_length += 1;
                }
            }
        }

        for (0..vertices) |destination| {
            const output = if (distance[destination] == std.math.maxInt(i64))
                UNREACHABLE_SENTINEL
            else
                distance[destination] - potential[source] + potential[destination];
            result = fnvWord(result, output);
        }
    }
    return @intCast(result & 0x7fff_ffff_ffff_ffff);
}

const std = @import("std");
