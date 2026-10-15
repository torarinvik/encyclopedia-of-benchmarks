/// Count vertex-simple directed paths with recursive DFS.
fn countFrom(matrix: []const i64, n: u32, current: u32, destination: u32, visited: u32) u32 {
    if (current == destination) return 1;
    const seen = visited | (@as(u32, 1) << @intCast(current));
    var count: u32 = 0;
    for (0..n) |next_usize| {
        const next: u32 = @intCast(next_usize);
        if (matrix[@as(usize, current * n + next)] == 1 and (seen & (@as(u32, 1) << @intCast(next))) == 0) {
            count += countFrom(matrix, n, next, destination, seen);
        }
    }
    return count;
}

export fn number_of_paths(values: [*]const i64, length: usize) i64 {
    if (length < 3 or values[0] < 1 or values[0] > 10) return -1;
    const n: u32 = @intCast(values[0]);
    if (length != 3 + @as(usize, n * n)) return -1;
    if (values[1] < 0 or values[1] > std.math.maxInt(u32) or values[2] < 0 or values[2] > std.math.maxInt(u32)) return -1;
    const matrix = values[3 .. 3 + @as(usize, n * n)];
    for (matrix) |cell| if (cell != 0 and cell != 1) return -1;
    const source: u32 = @intCast(values[1]);
    const destination: u32 = @intCast(values[2]);
    if (source >= n or destination >= n) return 0;
    return countFrom(matrix, n, source, destination, 0);
}

const std = @import("std");
