const MAX_VERTICES: usize = 7;
const MAX_EDGES: usize = 9;
const MAX_INPUT_LENGTH: usize = 20;
const MODULUS: i64 = 998_244_353;

fn modularPower(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (exponent & 1 != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

export fn counting_eulerian_circuits(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const m_value = values[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_VERTICES)) or
        m_value < 1 or m_value > @as(i64, @intCast(MAX_EDGES))) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(m_value);
    if (length != 2 + 2 * edge_count) return -1;

    var indegree = [_]usize{0} ** MAX_VERTICES;
    var outdegree = [_]usize{0} ** MAX_VERTICES;
    var start: usize = 0;
    for (0..edge_count) |edge| {
        const u_value = values[2 + 2 * edge];
        const v_value = values[3 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (edge == 0) start = u;
        outdegree[u] += 1;
        indegree[v] += 1;
    }

    var balanced = true;
    for (0..n) |vertex| {
        if (indegree[vertex] != outdegree[vertex]) balanced = false;
    }
    var answer: i64 = 0;
    if (balanced) {
        var active_id = [_]usize{MAX_VERTICES} ** MAX_VERTICES;
        var active_count: usize = 0;
        for (0..n) |vertex| {
            if (indegree[vertex] != 0) {
                active_id[vertex] = active_count;
                active_count += 1;
            }
        }
        const root_id = active_id[start];
        const dimension = active_count - 1;
        var matrix = [_][MAX_VERTICES]i64{[_]i64{0} ** MAX_VERTICES} ** MAX_VERTICES;
        for (0..edge_count) |edge| {
            const u: usize = @intCast(values[2 + 2 * edge]);
            const v: usize = @intCast(values[3 + 2 * edge]);
            if (u == start) continue;
            var row = active_id[u];
            if (row > root_id) row -= 1;
            matrix[row][row] = @mod(matrix[row][row] + 1, MODULUS);
            if (v != start) {
                var column = active_id[v];
                if (column > root_id) column -= 1;
                matrix[row][column] = @mod(matrix[row][column] + MODULUS - 1, MODULUS);
            }
        }

        var determinant: i64 = 1;
        for (0..dimension) |column| {
            var pivot = column;
            while (pivot < dimension and matrix[pivot][column] == 0) : (pivot += 1) {}
            if (pivot == dimension) {
                determinant = 0;
                break;
            }
            if (pivot != column) {
                for (0..dimension) |j| {
                    const temporary = matrix[column][j];
                    matrix[column][j] = matrix[pivot][j];
                    matrix[pivot][j] = temporary;
                }
                determinant = @mod(MODULUS - determinant, MODULUS);
            }
            const pivot_value = matrix[column][column];
            determinant = @mod(determinant * pivot_value, MODULUS);
            const inverse = modularPower(pivot_value, MODULUS - 2);
            for (column + 1..dimension) |row| {
                const factor = @mod(matrix[row][column] * inverse, MODULUS);
                for (column..dimension) |j| {
                    matrix[row][j] = @mod(matrix[row][j] - @mod(factor * matrix[column][j], MODULUS) + MODULUS, MODULUS);
                }
            }
        }
        answer = determinant;
        for (0..n) |vertex| {
            var factor: usize = 2;
            while (factor < outdegree[vertex]) : (factor += 1) {
                answer = @mod(answer * @as(i64, @intCast(factor)), MODULUS);
            }
        }
    }

    if (output == null or output_capacity < 8) return -2;
    const bytes = output.?;
    const encoded: u64 = @intCast(answer);
    for (0..8) |byte| bytes[byte] = @truncate(encoded >> (8 * byte));
    return 8;
}
