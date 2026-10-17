const MAX_VERTICES: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + MAX_VERTICES * MAX_VERTICES;
const MAX_WEIGHT: i64 = 32;
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

export fn johnsons_algorithm(input_pointer: ?[*]const i64, length: usize) i64 {
    const input = input_pointer orelse return -1;
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_value = input[0];
    if (vertex_value < 1 or vertex_value > MAX_VERTICES) return -1;
    const vertices: usize = @intCast(vertex_value);
    if (length != 1 + vertices * vertices) return -1;

    var weight = [_]i64{0} ** (MAX_VERTICES * MAX_VERTICES);
    var edge = [_]bool{false} ** (MAX_VERTICES * MAX_VERTICES);
    var reachable = [_]bool{false} ** (MAX_VERTICES * MAX_VERTICES);
    for (0..vertices) |from| {
        reachable[from * MAX_VERTICES + from] = true;
        for (0..vertices) |to| {
            const value = input[1 + from * vertices + to];
            if (value < -MAX_WEIGHT or value > MAX_WEIGHT) return -1;
            if (from != to and value != 0) {
                const index = from * MAX_VERTICES + to;
                edge[index] = true;
                weight[index] = value;
                reachable[index] = true;
            }
        }
    }
    for (0..vertices) |intermediate| {
        for (0..vertices) |from| {
            for (0..vertices) |to| {
                const index = from * MAX_VERTICES + to;
                reachable[index] = reachable[index] or
                    (reachable[from * MAX_VERTICES + intermediate] and
                     reachable[intermediate * MAX_VERTICES + to]);
            }
        }
    }
    for (0..vertices) |from| {
        for (0..vertices) |to| {
            if (!reachable[from * MAX_VERTICES + to]) return -1;
        }
    }

    var potential = [_]i64{0} ** MAX_VERTICES;
    for (1..vertices) |_| {
        var updated = false;
        for (0..vertices) |from| {
            for (0..vertices) |to| {
                const index = from * MAX_VERTICES + to;
                if (!edge[index]) continue;
                const candidate = potential[from] + weight[index];
                if (candidate < potential[to]) {
                    potential[to] = candidate;
                    updated = true;
                }
            }
        }
        if (!updated) break;
    }
    for (0..vertices) |from| {
        for (0..vertices) |to| {
            const index = from * MAX_VERTICES + to;
            if (!edge[index]) continue;
            if (potential[from] + weight[index] < potential[to] or
                weight[index] + potential[from] - potential[to] <= 0) return -1;
        }
    }

    var reweighted = [_]i64{0} ** (MAX_VERTICES * MAX_VERTICES);
    for (0..vertices) |from| {
        for (0..vertices) |to| {
            const index = from * MAX_VERTICES + to;
            if (edge[index]) reweighted[index] = weight[index] + potential[from] - potential[to];
        }
    }

    var result = FNV_OFFSET_BASIS;
    for (0..vertices) |source| {
        var distance = [_]i64{std.math.maxInt(i64)} ** MAX_VERTICES;
        var visited = [_]bool{false} ** MAX_VERTICES;
        distance[source] = 0;
        for (0..vertices) |_| {
            var current = vertices;
            for (0..vertices) |vertex| {
                if (!visited[vertex] and (current == vertices or distance[vertex] <= distance[current])) {
                    current = vertex;
                }
            }
            if (current == vertices or distance[current] == std.math.maxInt(i64)) break;
            visited[current] = true;
            for (0..vertices) |next| {
                const index = current * MAX_VERTICES + next;
                if (!edge[index] or visited[next]) continue;
                const candidate = distance[current] + reweighted[index];
                if (candidate < distance[next]) distance[next] = candidate;
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
