const std = @import("std");

const MOD: i64 = 998244353;
const MAX_N: usize = 8;
const MAX_K: usize = 64;
const MAX_PARSEABLE_INPUT: usize = 195;
const ATTEMPTS: usize = 4;

fn addMod(a: i64, b: i64) i64 {
    const value = a + b;
    return if (value >= MOD) value - MOD else value;
}
fn subMod(a: i64, b: i64) i64 {
    const value = a - b;
    return if (value < 0) value + MOD else value;
}
fn mulMod(a: i64, b: i64) i64 { return @mod(a * b, MOD); }
fn powMod(value_value: i64, exponent_value: i64) i64 {
    var value = value_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = mulMod(result, value);
        value = mulMod(value, value);
        exponent >>= 1;
    }
    return result;
}
fn nextResidue(state: *i64) i64 {
    state.* = @mod(state.* * 48271 + 1, MOD);
    return state.*;
}

fn berlekampMassey(sequence: []const i64, connection: []i64) usize {
    var previous = [_]i64{0} ** (MAX_N + 1);
    var temporary = [_]i64{0} ** (MAX_N + 1);
    @memset(connection, 0);
    connection[0] = 1;
    previous[0] = 1;
    var degree: usize = 0;
    var shift: usize = 1;
    var previous_degree: usize = 0;
    var last_discrepancy: i64 = 1;
    for (sequence, 0..) |term, index| {
        var discrepancy = term;
        for (1..degree + 1) |i| discrepancy = addMod(discrepancy, mulMod(connection[i], sequence[index - i]));
        if (discrepancy == 0) {
            shift += 1;
            continue;
        }
        @memcpy(temporary[0..], connection);
        const scale = mulMod(discrepancy, powMod(last_discrepancy, MOD - 2));
        for (0..previous_degree + 1) |i| {
            const target = i + shift;
            if (target <= MAX_N) connection[target] = subMod(connection[target], mulMod(scale, previous[i]));
        }
        if (2 * degree <= index) {
            const old_degree = degree;
            degree = index + 1 - degree;
            @memcpy(previous[0..], temporary[0..]);
            previous_degree = old_degree;
            last_discrepancy = discrepancy;
            shift = 1;
        } else {
            shift += 1;
        }
    }
    return degree;
}

fn denseDeterminant(row: []const usize, column: []const usize,
        entry: []const i64, n: usize) i64 {
    var matrix = [_]i64{0} ** (MAX_N * MAX_N);
    for (row, column, entry) |r, c, value| matrix[r * MAX_N + c] = value;
    var determinant: i64 = 1;
    for (0..n) |c| {
        var pivot = c;
        while (pivot < n and matrix[pivot * MAX_N + c] == 0) : (pivot += 1) {}
        if (pivot == n) return 0;
        if (pivot != c) {
            for (0..n) |j| {
                const temporary = matrix[c * MAX_N + j];
                matrix[c * MAX_N + j] = matrix[pivot * MAX_N + j];
                matrix[pivot * MAX_N + j] = temporary;
            }
            determinant = MOD - determinant;
        }
        const pivot_value = matrix[c * MAX_N + c];
        determinant = mulMod(determinant, pivot_value);
        const inverse = powMod(pivot_value, MOD - 2);
        for (c + 1..n) |i| {
            if (matrix[i * MAX_N + c] == 0) continue;
            const factor = mulMod(matrix[i * MAX_N + c], inverse);
            for (c + 1..n) |j| matrix[i * MAX_N + j] = subMod(matrix[i * MAX_N + j], mulMod(factor, matrix[c * MAX_N + j]));
            matrix[i * MAX_N + c] = 0;
        }
    }
    return determinant;
}

fn sparseWiedemann(row: []const usize, column: []const usize,
        entry: []const i64, n: usize, seed_value: i64, connection: []i64) ?i64 {
    var state = seed_value;
    var diagonal = [_]i64{0} ** MAX_N;
    var left = [_]i64{0} ** MAX_N;
    var vector = [_]i64{0} ** MAX_N;
    var next = [_]i64{0} ** MAX_N;
    var weighted = [_]i64{0} ** MAX_N;
    var sequence = [_]i64{0} ** (2 * MAX_N);
    var diagonal_product: i64 = 1;
    for (0..n) |i| {
        diagonal[i] = nextResidue(&state);
        if (diagonal[i] == 0) diagonal[i] = 1;
        left[i] = nextResidue(&state);
        vector[i] = nextResidue(&state);
        diagonal_product = mulMod(diagonal_product, diagonal[i]);
    }
    for (0..2 * n) |step| {
        var dot: i64 = 0;
        for (0..n) |i| dot = addMod(dot, mulMod(left[i], vector[i]));
        sequence[step] = dot;
        for (0..n) |i| weighted[i] = mulMod(diagonal[i], vector[i]);
        @memset(next[0..], 0);
        for (row, column, entry) |r, c, value| next[r] = addMod(next[r], mulMod(value, weighted[c]));
        vector = next;
    }
    if (berlekampMassey(sequence[0 .. 2 * n], connection[0..]) != n) return null;
    var constant = connection[n];
    if ((n & 1) != 0 and constant != 0) constant = MOD - constant;
    return mulMod(constant, powMod(diagonal_product, MOD - 2));
}

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn sparse_matrix_det(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const k_value = input[1];
    if (n_value < 1 or n_value > MAX_N or k_value < 1 or k_value > MAX_K) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != 2 + 3 * k) return -1;
    var seen = [_]bool{false} ** (MAX_N * MAX_N);
    var row = [_]usize{0} ** MAX_K;
    var column = [_]usize{0} ** MAX_K;
    var entry = [_]i64{0} ** MAX_K;
    for (0..k) |e| {
        const r_value = input[2 + 3 * e];
        const c_value = input[3 + 3 * e];
        const value = input[4 + 3 * e];
        if (r_value < 0 or r_value >= n_value or c_value < 0 or c_value >= n_value or value < 1 or value >= MOD) return -1;
        const r: usize = @intCast(r_value);
        const c: usize = @intCast(c_value);
        const index = r * MAX_N + c;
        if (seen[index]) return -1;
        seen[index] = true;
        row[e] = r; column[e] = c; entry[e] = value;
    }
    var determinant: ?i64 = null;
    var connection = [_]i64{0} ** (MAX_N + 1);
    for (0..ATTEMPTS) |attempt| {
        var seed: i64 = 104729 + @as(i64, @intCast(attempt)) * 1000003;
        if (seed >= MOD) seed = @mod(seed, MOD);
        determinant = sparseWiedemann(row[0..k], column[0..k], entry[0..k], n, seed, connection[0..]);
        if (determinant != null) break;
    }
    const answer = determinant orelse denseDeterminant(row[0..k], column[0..k], entry[0..k], n);
    if (output_opt == null or capacity < 8) return -2;
    storeI64Le(output_opt.?, answer);
    return 8;
}
