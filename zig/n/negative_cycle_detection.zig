// Clean-room negative-cycle detection and witness extraction.
const max_n: usize = 20;
const max_m: usize = 64;
const max_input: usize = 2 + 3 * max_m;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn negative_cycle_detection(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 0 or n64 > 20 or m64 < 0 or m64 > 64 or length != 2 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var from = [_]usize{0} ** max_m;
    var to = [_]usize{0} ** max_m;
    var weight = [_]i64{0} ** max_m;
    for (0..m) |edge| {
        const u64 = input[2 + 3 * edge]; const v64 = input[3 + 3 * edge]; const w = input[4 + 3 * edge];
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or w < -1000 or w > 1000) return -1;
        from[edge] = @intCast(u64); to[edge] = @intCast(v64); weight[edge] = w;
    }
    var distance = [_]i64{0} ** max_n;
    var predecessor = [_]i64{-1} ** max_n;
    var changed_vertex: i64 = -1;
    for (0..n) |_| {
        changed_vertex = -1;
        for (0..m) |edge| {
            const u = from[edge]; const v = to[edge];
            const candidate = distance[u] + weight[edge];
            if (candidate < distance[v]) { distance[v] = candidate; predecessor[v] = @intCast(u); changed_vertex = @intCast(v); }
        }
        if (changed_vertex < 0) break;
    }
    var record = [_]i64{0} ** (max_n + 2);
    var record_length: usize = 1;
    if (changed_vertex >= 0) {
        var vertex: usize = @intCast(changed_vertex);
        for (0..n) |_| {
            if (predecessor[vertex] < 0) return -1;
            vertex = @intCast(predecessor[vertex]);
        }
        const start = vertex;
        var cycle = [_]usize{0} ** max_n;
        var cycle_length: usize = 0;
        while (true) {
            if (cycle_length >= n or predecessor[vertex] < 0) return -1;
            cycle[cycle_length] = vertex; cycle_length += 1;
            vertex = @intCast(predecessor[vertex]);
            if (vertex == start) break;
        }
        std.mem.reverse(usize, cycle[0..cycle_length]);
        var minimum: usize = 0;
        for (1..cycle_length) |i| { if (cycle[i] < cycle[minimum]) minimum = i; }
        record[0] = 1; record[1] = @intCast(cycle_length);
        for (0..cycle_length) |i| record[2+i] = @intCast(cycle[(minimum+i)%cycle_length]);
        record_length = cycle_length + 2;
    } else { record[0] = 0; }
    const output_length = 8 * record_length;
    if (output_opt == null or capacity < output_length) return -2;
    const output = output_opt.?;
    for (0..record_length) |i| storeI64LE(output, 8*i, record[i]);
    return @intCast(output_length);
}

const std = @import("std");
