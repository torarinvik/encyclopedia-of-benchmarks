const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 87;
const MAX_OUTPUT: usize = 80;
const PRIME: i64 = 65521;

fn norm(value: i64) i64 {
    const remainder = @rem(value, PRIME);
    return if (remainder < 0) remainder + PRIME else remainder;
}

fn power(base: i64, exponent_value: u64) i64 {
    var exponent = exponent_value;
    var result: i64 = 1;
    var factor = norm(base);
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = @rem(result * factor, PRIME);
        factor = @rem(factor * factor, PRIME);
        exponent >>= 1;
    }
    return result;
}

fn storeWord(bytes: []u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| bytes[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn eliminate(inverse: *[MAX_N * MAX_N]i64, rows: *[MAX_N]bool,
    columns: *[MAX_N]bool, n: usize, pivot_row: usize, pivot_column: usize) bool {
    const old = inverse.*;
    const pivot = old[pivot_row * MAX_N + pivot_column];
    if (pivot == 0) return false;
    const inverse_pivot = power(pivot, @intCast(PRIME - 2));
    for (0..n) |row| {
        for (0..n) |column| {
            const index = row * MAX_N + column;
            if (rows[row] and row != pivot_row and columns[column] and column != pivot_column) {
                const correction = @rem(old[row * MAX_N + pivot_column] * old[pivot_row * MAX_N + column], PRIME);
                inverse[index] = norm(old[index] - correction * inverse_pivot);
            } else inverse[index] = 0;
        }
    }
    rows[pivot_row] = false;
    columns[pivot_column] = false;
    return true;
}

export fn tutte_matrix_randomized_perfect_matching(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const edge_count_value = input[1];
    if (n_value < 2 or n_value > MAX_N or @rem(n_value, 2) != 0 or
        edge_count_value < 0 or edge_count_value > MAX_EDGES) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(edge_count_value);
    if (edge_count > n * (n - 1) / 2 or length != 2 + 3 * edge_count) return -1;

    var matrix = [_]i64{0} ** (MAX_N * MAX_N);
    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..edge_count) |edge| {
        const u_value = input[2 + 3 * edge];
        const v_value = input[3 + 3 * edge];
        const substitution = input[4 + 3 * edge];
        if (u_value < 0 or v_value <= u_value or v_value >= n_value or
            u_value < previous_u or (u_value == previous_u and v_value <= previous_v) or
            substitution < 1 or substitution >= PRIME) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        matrix[u * MAX_N + v] = substitution;
        matrix[v * MAX_N + u] = PRIME - substitution;
        previous_u = u_value;
        previous_v = v_value;
    }

    var augmented = [_]i64{0} ** (MAX_N * (2 * MAX_N));
    for (0..n) |row| {
        for (0..n) |column| augmented[row * (2 * MAX_N) + column] = matrix[row * MAX_N + column];
        augmented[row * (2 * MAX_N) + n + row] = 1;
    }
    var singular = false;
    for (0..n) |column| {
        var pivot_row = column;
        while (pivot_row < n and augmented[pivot_row * (2 * MAX_N) + column] == 0) : (pivot_row += 1) {}
        if (pivot_row == n) { singular = true; break; }
        if (pivot_row != column) {
            for (0..2 * n) |j| {
                const temporary = augmented[column * (2 * MAX_N) + j];
                augmented[column * (2 * MAX_N) + j] = augmented[pivot_row * (2 * MAX_N) + j];
                augmented[pivot_row * (2 * MAX_N) + j] = temporary;
            }
        }
        const pivot = augmented[column * (2 * MAX_N) + column];
        const inverse_pivot = power(pivot, @intCast(PRIME - 2));
        for (0..2 * n) |j| augmented[column * (2 * MAX_N) + j] =
            @rem(augmented[column * (2 * MAX_N) + j] * inverse_pivot, PRIME);
        for (0..n) |row| {
            if (row == column) continue;
            const factor = augmented[row * (2 * MAX_N) + column];
            if (factor == 0) continue;
            for (0..2 * n) |j| augmented[row * (2 * MAX_N) + j] = norm(
                augmented[row * (2 * MAX_N) + j] - factor * augmented[column * (2 * MAX_N) + j]);
        }
    }

    var result = [_]i64{0} ** (2 + MAX_N);
    var result_size: usize = 2;
    if (!singular) {
        var inverse = [_]i64{0} ** (MAX_N * MAX_N);
        for (0..n) |row| {
            for (0..n) |column| {
                inverse[row * MAX_N + column] = augmented[row * (2 * MAX_N) + n + column];
            }
        }
        var rows = [_]bool{false} ** MAX_N;
        var columns = [_]bool{false} ** MAX_N;
        for (0..n) |i| { rows[i] = true; columns[i] = true; }
        var failed = false;
        for (0..n) |vertex| {
            if (!columns[vertex]) continue;
            var partner: ?usize = null;
            for (0..n) |candidate| {
                if (rows[candidate] and candidate != vertex and
                    matrix[vertex * MAX_N + candidate] != 0 and
                    inverse[candidate * MAX_N + vertex] != 0) {
                    partner = candidate;
                    break;
                }
            }
            if (partner == null or result_size + 2 > result.len) { failed = true; break; }
            const other = partner.?;
            result[result_size] = @intCast(vertex);
            result[result_size + 1] = @intCast(other);
            result_size += 2;
            if (!eliminate(&inverse, &rows, &columns, n, other, vertex) or
                !eliminate(&inverse, &rows, &columns, n, vertex, other)) {
                failed = true;
                break;
            }
        }
        if (failed) result_size = 2 else { result[0] = 1; result[1] = @intCast(n / 2); }
    }
    const output_bytes = result_size * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    for (0..result_size) |word| storeWord(staged[0..], word, result[word]);
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
