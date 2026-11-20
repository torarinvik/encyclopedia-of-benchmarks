const MAX_N: usize = 8;
const MATRIX_WIDTH: usize = 17;
const MAX_INPUT_LENGTH: usize = 115;
const MODULUS: i64 = 1_000_000_007;
const Matrix = [MAX_N][MATRIX_WIDTH]i64;

fn norm(input: i64) i64 {
    const value = @mod(input, MODULUS);
    return if (value < 0) value + MODULUS else value;
}

fn power(base_input: i64, exponent_input: i64) i64 {
    var base = norm(base_input);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn reachesAll(graph: [MAX_N][MAX_N]bool, n: usize, reverse: bool) bool {
    var seen: [MAX_N]bool = @splat(false);
    var queue: [MAX_N]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    seen[0] = true;
    queue[0] = 0;
    while (head < tail) : (head += 1) {
        const current = queue[head];
        for (0..n) |to| {
            const edge = if (reverse) graph[to][current] else graph[current][to];
            if (edge and !seen[to]) {
                seen[to] = true;
                queue[tail] = to;
                tail += 1;
            }
        }
    }
    return tail == n;
}

fn eliminate(matrix: *Matrix, size: usize, rhs_count: usize) bool {
    const width = size + rhs_count;
    for (0..size) |column| {
        var pivot = column;
        while (pivot < size and norm(matrix.*[pivot][column]) == 0) : (pivot += 1) {}
        if (pivot == size) return false;
        if (pivot != column) {
            for (0..width) |j| {
                const temporary = matrix.*[column][j];
                matrix.*[column][j] = matrix.*[pivot][j];
                matrix.*[pivot][j] = temporary;
            }
        }
        const inverse = power(matrix.*[column][column], MODULUS - 2);
        for (0..width) |j| matrix.*[column][j] = @mod(matrix.*[column][j] * inverse, MODULUS);
        for (0..size) |row| {
            if (row == column) continue;
            const factor = norm(matrix.*[row][column]);
            if (factor == 0) continue;
            for (0..width) |j|
                matrix.*[row][j] = norm(matrix.*[row][j] - @mod(factor * matrix.*[column][j], MODULUS));
        }
    }
    return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn all_pairs_directed_random_walk_hitting_times(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 3 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    if (m_value < 0 or m_value > n_value * (n_value - 1)) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var graph: [MAX_N][MAX_N]bool = undefined;
    for (0..MAX_N) |i| graph[i] = @splat(false);
    var degree: [MAX_N]usize = @splat(0);
    for (0..m) |edge| {
        const u_value = input[2 + 2 * edge];
        const v_value = input[3 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (graph[u][v]) return -1;
        graph[u][v] = true;
        degree[u] += 1;
    }
    for (0..n) |vertex| if (degree[vertex] == 0) return -1;
    if (!reachesAll(graph, n, false) or !reachesAll(graph, n, true)) return -1;
    const output_bytes = 8 * n * n;
    if (output_opt == null or capacity < output_bytes) return -2;

    var stationary: Matrix = undefined;
    for (0..MAX_N) |i| stationary[i] = @splat(0);
    for (0..n - 1) |destination| {
        for (0..n) |source| {
            const transition = if (graph[source][destination]) power(@intCast(degree[source]), MODULUS - 2) else 0;
            stationary[destination][source] = norm(transition - @as(i64, if (source == destination) 1 else 0));
        }
    }
    for (0..n) |source| stationary[n - 1][source] = 1;
    stationary[n - 1][n] = 1;
    if (!eliminate(&stationary, n, 1)) return -1;
    var reciprocal: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| {
        const pi = norm(stationary[vertex][n]);
        if (pi == 0) return -1;
        reciprocal[vertex] = power(pi, MODULUS - 2);
    }

    var reduced: Matrix = undefined;
    for (0..MAX_N) |i| reduced[i] = @splat(0);
    for (0..n - 1) |row| {
        for (0..n - 1) |column| {
            const transition = if (graph[row][column]) power(@intCast(degree[row]), MODULUS - 2) else 0;
            reduced[row][column] = norm(@as(i64, if (row == column) 1 else 0) - transition);
        }
        for (0..n) |target| {
            const correction = if (row == target) reciprocal[target] else 0;
            reduced[row][n - 1 + target] = norm(1 - correction);
        }
    }
    if (!eliminate(&reduced, n - 1, n)) return -1;
    var y: [MAX_N][MAX_N]i64 = undefined;
    for (0..MAX_N) |i| y[i] = @splat(0);
    for (0..n - 1) |row|
        for (0..n) |target| y[row][target] = norm(reduced[row][n - 1 + target]);
    const output = output_opt.?;
    for (0..n) |source| {
        for (0..n) |target| {
            storeI64Le(output, 8 * (source * n + target), norm(y[source][target] - y[target][target]));
        }
    }
    return @intCast(output_bytes);
}
