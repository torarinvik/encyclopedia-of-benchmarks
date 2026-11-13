const Matrix = [8][8]i64;

fn distances(adjacency: Matrix, n: usize) Matrix {
    var squared: Matrix = @splat(@splat(0));
    var expanded: Matrix = @splat(@splat(0));
    var result: Matrix = @splat(@splat(0));
    var degree: [8]i64 = @splat(0);
    var complete = true;
    for (0..n) |i| {
        for (0..n) |j| {
            degree[i] += adjacency[i][j];
            if (i != j and adjacency[i][j] == 0) complete = false;
            for (0..n) |k| squared[i][j] += adjacency[i][k] * adjacency[k][j];
        }
    }
    if (complete) {
        for (0..n) |i| {
            for (0..n) |j| {
                if (i != j) result[i][j] = 1;
            }
        }
        return result;
    }
    for (0..n) |i| {
        for (0..n) |j| {
            if (i != j and (adjacency[i][j] != 0 or squared[i][j] != 0)) expanded[i][j] = 1;
        }
    }
    const coarse = distances(expanded, n);
    for (0..n) |i| {
        for (0..n) |j| {
            if (i == j) continue;
            var neighbor_sum: i64 = 0;
            for (0..n) |k| neighbor_sum += coarse[i][k] * adjacency[k][j];
            result[i][j] = 2 * coarse[i][j];
            if (neighbor_sum < coarse[i][j] * degree[j]) result[i][j] -= 1;
        }
    }
    return result;
}

export fn seidel_unweighted_apsp(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return -1;
    var adjacency: Matrix = @splat(@splat(0));
    for (0..n) |i| {
        for (0..n) |j| {
            const value = input[1 + i * n + j];
            if (value < 0 or value > 1 or (i == j and value != 0)) return -1;
            adjacency[i][j] = value;
        }
    }
    for (0..n) |i| {
        for (0..i) |j| if (adjacency[i][j] != adjacency[j][i]) return -1;
    }
    var seen: [8]bool = @splat(false);
    var queue: [8]usize = @splat(0);
    seen[0] = true;
    var head: usize = 0;
    var tail: usize = 1;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        for (0..n) |other| {
            if (adjacency[vertex][other] != 0 and !seen[other]) {
                seen[other] = true;
                queue[tail] = other;
                tail += 1;
            }
        }
    }
    if (tail != n) return -1;
    const bytes = 8 * n * n;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    const result = distances(adjacency, n);
    for (0..n) |i| {
        for (0..n) |j| {
            const bits: u64 = @intCast(result[i][j]);
            for (0..8) |byte| output[8 * (i * n + j) + byte] = @truncate(bits >> @intCast(8 * byte));
        }
    }
    return @intCast(bytes);
}
