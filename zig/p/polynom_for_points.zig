const std = @import("std");

const min_points: usize = 2;
const max_points: usize = 8;
const min_x: i64 = -4;
const max_x: i64 = 4;
const min_y: i64 = -25000;
const max_y: i64 = 25000;
const max_coefficient: f64 = 1000000.0;
const max_contract_bytes: usize = 124;
const scratch_bytes: usize = 125;

fn appendText(buffer: *[scratch_bytes]u8, position_value: usize, text: []const u8) usize {
    var position = position_value;
    for (text) |byte| { buffer[position] = byte; position += 1; }
    return position;
}

fn appendI64(buffer: *[scratch_bytes]u8, position_value: usize, value_value: i64) usize {
    var position = position_value;
    var value = value_value;
    var digits: [24]u8 = undefined;
    var count: usize = 0;
    if (value < 0) { buffer[position] = '-'; position += 1; value = -value; }
    while (true) {
        digits[count] = @intCast(@as(i64, '0') + @mod(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    while (count > 0) { count -= 1; buffer[position] = digits[count]; position += 1; }
    return position;
}

fn appendCoefficient(buffer: *[scratch_bytes]u8, position_value: usize, value: f64) usize {
    var position = position_value;
    if (value == 0.0) {
        if (@as(u64, @bitCast(value)) >> 63 != 0) { buffer[position] = '-'; position += 1; }
        return appendText(buffer, position, "0.0");
    }
    position = appendI64(buffer, position, @intFromFloat(value));
    return appendText(buffer, position, ".0");
}

export fn polynom_for_points(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 1 + 2 * max_points) return -1;
    const raw_n = values[0];
    if (raw_n < @as(i64, @intCast(min_points)) or raw_n > @as(i64, @intCast(max_points)) or
        length != 1 + 2 * @as(usize, @intCast(raw_n))) return -1;
    const n: usize = @intCast(raw_n);
    var xs = [_]i64{0} ** max_points;
    var matrix = [_][max_points]f64{[_]f64{0.0} ** max_points} ** max_points;
    var vector = [_]f64{0.0} ** max_points;
    for (0..n) |row| {
        const x = values[1 + 2 * row];
        const y = values[2 + 2 * row];
        if (x < min_x or x > max_x or y < min_y or y > max_y) return -1;
        for (0..row) |previous| { if (xs[previous] == x) return -1; }
        xs[row] = x;
        for (0..n) |column| {
            var power: i64 = 1;
            for (0..(n - column - 1)) |_| { power *= x; }
            matrix[row][column] = @floatFromInt(power);
        }
        vector[row] = @floatFromInt(y);
    }

    for (0..n) |count| {
        if (matrix[count][count] == 0.0) {
            var pivot_row = count + 1;
            for (count + 2..n) |row| {
                if (@abs(matrix[row][count]) > @abs(matrix[pivot_row][count])) pivot_row = row;
            }
            if (pivot_row >= n or matrix[pivot_row][count] == 0.0) return -1;
            for (0..n) |column| {
                const temporary = matrix[count][column];
                matrix[count][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            const temporary = vector[count];
            vector[count] = vector[pivot_row];
            vector[pivot_row] = temporary;
        }
        for (0..n) |row| {
            if (row == count) continue;
            const fraction = matrix[row][count] / matrix[count][count];
            for (0..n) |column| {
                const product = matrix[count][column] * fraction;
                matrix[row][column] = matrix[row][column] - product;
            }
            const product = vector[count] * fraction;
            vector[row] = vector[row] - product;
        }
    }

    var coefficients = [_]f64{0.0} ** max_points;
    for (0..n) |index| {
        const value = vector[index] / matrix[index][index];
        if (!std.math.isFinite(value) or @abs(value) > max_coefficient or @trunc(value) != value) return -1;
        coefficients[index] = value;
    }

    var buffer: [scratch_bytes]u8 = undefined;
    var position = appendText(&buffer, 0, "f(x)=");
    for (0..n) |index| {
        if (index != 0) { buffer[position] = '+'; position += 1; }
        position = appendText(&buffer, position, "x^");
        position = appendI64(&buffer, position, @intCast(n - index - 1));
        buffer[position] = '*'; position += 1;
        position = appendCoefficient(&buffer, position, coefficients[index]);
    }
    if (position > max_contract_bytes) return -1;
    if (output == null or output_capacity < position) return -2;
    for (0..position) |index| output[index] = buffer[index];
    return @intCast(position);
}
