const MAX_VERTICES: usize = 6;
const MAX_EDGES: usize = 12;
const MAX_INPUT_LENGTH: usize = 27;
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

export fn counting_spanning_trees_directed(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    const m_value = values[1];
    const root_value = values[2];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_VERTICES)) or
        m_value < 0 or m_value > @as(i64, @intCast(MAX_EDGES)) or
        root_value < 0 or root_value >= n_value) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(m_value);
    const root: usize = @intCast(root_value);
    if (length != 3 + 2 * edge_count) return -1;

    const dimension = n - 1;
    var matrix = [_][MAX_VERTICES]i64{[_]i64{0} ** MAX_VERTICES} ** MAX_VERTICES;
    for (0..edge_count) |edge| {
        const u_value = values[3 + 2 * edge];
        const v_value = values[4 + 2 * edge];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (u == v or v == root) continue;
        const row = if (v < root) v else v - 1;
        matrix[row][row] = @mod(matrix[row][row] + 1, MODULUS);
        if (u != root) {
            const column = if (u < root) u else u - 1;
            matrix[row][column] = @mod(matrix[row][column] + MODULUS - 1, MODULUS);
        }
    }
    if (output == null or output_capacity < 8) return -2;

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
    const bytes = output.?;
    const answer: u64 = @intCast(determinant);
    for (0..8) |byte| bytes[byte] = @truncate(answer >> (8 * byte));
    return 8;
}
