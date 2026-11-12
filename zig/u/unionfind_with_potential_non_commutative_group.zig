const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const MODULUS: i64 = 998_244_353;
const Matrix = [4]i64;

fn normalize(value_input: i64) i64 {
    const value = @mod(value_input, MODULUS);
    return if (value < 0) value + MODULUS else value;
}

fn multiply(left: Matrix, right: Matrix) Matrix {
    var result: Matrix = @splat(0);
    for (0..2) |row| {
        for (0..2) |column| {
            for (0..2) |inner| {
                const index = 2 * row + column;
                result[index] = normalize(result[index] + left[2 * row + inner] * right[2 * inner + column]);
            }
        }
    }
    return result;
}

fn inverse(matrix: Matrix) Matrix {
    return .{ matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0] };
}

fn equal(left: Matrix, right: Matrix) bool {
    for (0..4) |cell| if (left[cell] != right[cell]) return false;
    return true;
}

fn findRoot(parent: *[MAX_N]usize, difference: *[MAX_N]Matrix, item: usize) usize {
    if (parent[item] != item) {
        const old_parent = parent[item];
        const root = findRoot(parent, difference, old_parent);
        difference[item] = multiply(difference[old_parent], difference[item]);
        parent[item] = root;
    }
    return parent[item];
}

fn readMatrix(input: [*c]const i64, offset: usize) Matrix {
    return .{ input[offset], input[offset + 1], input[offset + 2], input[offset + 3] };
}

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn unionfind_with_potential_non_commutative_group(input: [*c]const i64,
    length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 9 or length > 2 + 7 * MAX_Q) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        q_value < 1 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + 7 * q) return -1;
    for (0..q) |operation| {
        const position = 2 + 7 * operation;
        const kind = input[position];
        const u = input[position + 1];
        const v = input[position + 2];
        if (u < 0 or u >= n_value or v < 0 or v >= n_value) return -1;
        if (kind == 0) {
            const matrix = readMatrix(input, position + 3);
            for (matrix) |entry| if (entry < 0 or entry >= MODULUS) return -1;
            if (normalize(matrix[0] * matrix[3] - matrix[1] * matrix[2]) != 1) return -1;
        } else if (kind == 1) {
            for (0..4) |cell| if (input[position + 3 + cell] != 0) return -1;
        } else return -1;
    }
    const required = 32 * q;
    if (output == null or capacity < required) return -2;

    var parent: [MAX_N]usize = undefined;
    var set_size: [MAX_N]usize = undefined;
    var difference: [MAX_N]Matrix = undefined;
    for (0..n) |item| {
        parent[item] = item;
        set_size[item] = 1;
        difference[item] = .{ 1, 0, 0, 1 };
    }
    for (0..q) |operation| {
        const position = 2 + 7 * operation;
        const kind = input[position];
        const u: usize = @intCast(input[position + 1]);
        const v: usize = @intCast(input[position + 2]);
        var row: Matrix = @splat(0);
        const root_u = findRoot(&parent, &difference, u);
        const root_v = findRoot(&parent, &difference, v);
        if (kind == 1) {
            if (root_u == root_v) row = multiply(inverse(difference[v]), difference[u]) else row = @splat(-1);
        } else {
            const relation = readMatrix(input, position + 3);
            if (root_u == root_v) {
                row[0] = if (equal(multiply(inverse(difference[v]), difference[u]), relation)) 1 else 0;
            } else if (set_size[root_u] < set_size[root_v]) {
                difference[root_u] = multiply(multiply(difference[v], relation), inverse(difference[u]));
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
                row[0] = 1;
            } else {
                difference[root_v] = multiply(multiply(difference[u], inverse(relation)), inverse(difference[v]));
                parent[root_v] = root_u;
                set_size[root_u] += set_size[root_v];
                row[0] = 1;
            }
        }
        for (0..4) |cell| writeI64(output, 32 * operation + 8 * cell, row[cell]);
    }
    return @intCast(required);
}
