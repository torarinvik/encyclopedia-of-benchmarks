const std = @import("std");
const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

fn magnitude(value: f64) f64 {
    return if (value < 0) -value else value;
}

export fn lu_pivot_decomposition(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 1, MAX_DIMENSION)) return -1;
    const dimension: usize = @intFromFloat(values[0]);
    const matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    var packed_lu = [_]f64{0} ** 16;
    for (0..matrix_elements) |index| {
        if (!exactInteger(values[index + 1], -8, 8)) return -1;
        packed_lu[index] = values[index + 1];
    }
    var pivot = [_]i64{0} ** 5;
    for (0..dimension + 1) |index| pivot[index] = @intCast(index);

    for (0..dimension) |column| {
        var max_value: f64 = 0;
        var max_index = column;
        for (column..dimension) |row| {
            const current_magnitude = magnitude(packed_lu[row * dimension + column]);
            if (current_magnitude > max_value) {
                max_value = current_magnitude;
                max_index = row;
            }
        }
        if (max_index != column) {
            std.mem.swap(i64, &pivot[column], &pivot[max_index]);
            for (0..dimension) |swap_column| {
                std.mem.swap(f64, &packed_lu[column * dimension + swap_column], &packed_lu[max_index * dimension + swap_column]);
            }
            pivot[dimension] += 1;
        }

        const pivot_value = packed_lu[column * dimension + column];
        if (pivot_value == 0 or !std.math.isFinite(pivot_value)) return -1;
        for (column + 1..dimension) |row| {
            const multiplier_index = row * dimension + column;
            packed_lu[multiplier_index] /= pivot_value;
            if (!std.math.isFinite(packed_lu[multiplier_index])) return -1;
            for (column + 1..dimension) |trailing_column| {
                const index = row * dimension + trailing_column;
                packed_lu[index] -= packed_lu[multiplier_index] * packed_lu[column * dimension + trailing_column];
                if (!std.math.isFinite(packed_lu[index])) return -1;
            }
        }
    }

    const output_length = matrix_elements + dimension + 1;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..matrix_elements) |index| out[index] = packed_lu[index];
    for (0..dimension + 1) |index| out[matrix_elements + index] = @floatFromInt(pivot[index]);
    return @intCast(output_length);
}
