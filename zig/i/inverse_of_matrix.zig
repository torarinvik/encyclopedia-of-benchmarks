const MAX_INPUT_VALUES: usize = 11;
const COEFFICIENT_LIMIT: i64 = 32;

noinline fn roundedMultiply(left: f64, right: f64) f64 { return left * right; }
noinline fn roundedSubtract(left: f64, right: f64) f64 { return left - right; }
noinline fn roundedDivide(left: f64, right: f64) f64 { return left / right; }

fn validDominance(matrix: *const [9]f64, n: usize) bool {
    var seen = [_]bool{false} ** 3;
    for (0..n) |row| {
        var dominant: ?usize = null;
        for (0..n) |column| {
            var other_sum: f64 = 0;
            for (0..n) |other| if (other != column) { other_sum += @abs(matrix[row * n + other]); };
            if (@abs(matrix[row * n + column]) > other_sum) {
                if (dominant != null) return false;
                dominant = column;
            }
        }
        const column = dominant orelse return false;
        if (seen[column]) return false;
        seen[column] = true;
    }
    return true;
}

fn invert(matrix: *[9]f64, n: usize) [9]f64 {
    var inverse = [_]f64{0} ** 9;
    var identity = [_]f64{0} ** 9;
    var index = [_]usize{0} ** 3;
    var scale = [_]f64{0} ** 3;
    for (0..n) |row| {
        index[row] = row;
        identity[row * n + row] = 1;
        for (0..n) |column| scale[row] = @max(scale[row], @abs(matrix[row * n + column]));
    }
    for (0..n - 1) |column| {
        var best: f64 = 0;
        var pivot_slot = column;
        for (column..n) |slot| {
            const row = index[slot];
            const ratio = roundedDivide(@abs(matrix[row * n + column]), scale[row]);
            if (ratio > best) { best = ratio; pivot_slot = slot; }
        }
        const tmp = index[column]; index[column] = index[pivot_slot]; index[pivot_slot] = tmp;
        const pivot = index[column];
        for (column + 1..n) |slot| {
            const row = index[slot];
            const ratio = roundedDivide(matrix[row * n + column], matrix[pivot * n + column]);
            matrix[row * n + column] = ratio;
            for (column + 1..n) |trailing| {
                const product = roundedMultiply(ratio, matrix[pivot * n + trailing]);
                matrix[row * n + trailing] = roundedSubtract(matrix[row * n + trailing], product);
            }
        }
    }
    for (0..n - 1) |pivot| for (pivot + 1..n) |slot| {
        const row = index[slot]; const pivot_row = index[pivot];
        for (0..n) |rhs| {
            const product = roundedMultiply(matrix[row * n + pivot], identity[pivot_row * n + rhs]);
            identity[row * n + rhs] = roundedSubtract(identity[row * n + rhs], product);
        }
    };
    for (0..n) |rhs| {
        const last_row = index[n - 1];
        inverse[(n - 1) * n + rhs] = roundedDivide(identity[last_row * n + rhs], matrix[last_row * n + n - 1]);
        var row = n - 1;
        while (row > 0) {
            row -= 1;
            const source = index[row]; var value = identity[source * n + rhs];
            for (row + 1..n) |column| {
                const product = roundedMultiply(matrix[source * n + column], inverse[column * n + rhs]);
                value = roundedSubtract(value, product);
            }
            inverse[row * n + rhs] = roundedDivide(value, matrix[source * n + row]);
        }
    }
    return inverse;
}

export fn inverse_of_matrix(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_INPUT_VALUES or (values[0] != 2 and values[0] != 3)) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + n * n) return -1;
    var matrix = [_]f64{0} ** 9;
    for (0..n * n) |i| {
        const q = values[i + 1]; if (q < -COEFFICIENT_LIMIT or q > COEFFICIENT_LIMIT) return -1;
        matrix[i] = @as(f64, @floatFromInt(q)) / 16.0;
    }
    if (!validDominance(&matrix, n)) return -1;
    const inverse = invert(&matrix, n);
    for (0..n * n) |i| if (!std.math.isFinite(inverse[i]) or @abs(inverse[i]) > 32768.0) return -1;
    const bytes = n * n * 8;
    const out = output orelse return -2;
    if (capacity < bytes) return -2;
    for (0..n * n) |i| {
        const bits: u64 = @bitCast(inverse[i]);
        for (0..8) |b| out[i * 8 + b] = @truncate(bits >> @as(u6, @intCast(b * 8)));
    }
    return @intCast(bytes);
}

const std = @import("std");
