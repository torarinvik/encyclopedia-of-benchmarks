const std = @import("std");

const max_group_count: usize = 4;
const max_rows: usize = 4;
const max_columns: usize = 4;
const max_matrix_elements: usize = 16;
const max_group_matrix_elements: usize = 32;
const max_call_count: usize = 8;
const max_valid_input_length: usize = 271;
const max_parseable_input_length: usize = 272;

fn orthogonalize(gradient: [*]const f64, rows: usize, columns: usize, ns_steps: usize) [max_matrix_elements]f64 {
    const transposed = rows < columns;
    const working_rows = if (transposed) columns else rows;
    const working_columns = if (transposed) rows else columns;
    var matrix = [_]f64{0.0} ** max_matrix_elements;
    for (0..rows) |row| {
        for (0..columns) |column| {
            if (transposed) {
                matrix[column * working_columns + row] = gradient[row * columns + column];
            } else {
                matrix[row * working_columns + column] = gradient[row * columns + column];
            }
        }
    }
    for (0..ns_steps) |_| {
        var gram = [_]f64{0.0} ** max_matrix_elements;
        var product = [_]f64{0.0} ** max_matrix_elements;
        for (0..working_columns) |left| {
            for (0..working_columns) |right| {
                var sum = 0.0;
                for (0..working_rows) |row| {
                    sum += matrix[row * working_columns + left] * matrix[row * working_columns + right];
                }
                gram[left * working_columns + right] = sum;
            }
        }
        for (0..working_rows) |row| {
            for (0..working_columns) |column| {
                var sum = 0.0;
                for (0..working_columns) |inner| {
                    sum += matrix[row * working_columns + inner] * gram[inner * working_columns + column];
                }
                product[row * working_columns + column] = sum;
            }
        }
        for (0..working_rows) |row| {
            for (0..working_columns) |column| {
                const index = row * working_columns + column;
                matrix[index] = 1.5 * matrix[index] - 0.5 * product[index];
            }
        }
    }
    var result = [_]f64{0.0} ** max_matrix_elements;
    for (0..rows) |row| {
        for (0..columns) |column| {
            result[row * columns + column] = if (transposed)
                matrix[column * working_columns + row]
            else
                matrix[row * working_columns + column];
        }
    }
    return result;
}

export fn muon_optimizer(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 10 or input_length > max_parseable_input_length) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(values[index])) return -1;
    }
    const group_value = values[0];
    const rows_value = values[1];
    const columns_value = values[2];
    const calls_value = values[3];
    const steps_value = values[4];
    if (group_value < 1.0 or group_value > @as(f64, @floatFromInt(max_group_count)) or
        rows_value < 1.0 or rows_value > @as(f64, @floatFromInt(max_rows)) or
        columns_value < 1.0 or columns_value > @as(f64, @floatFromInt(max_columns)) or
        calls_value < 1.0 or calls_value > @as(f64, @floatFromInt(max_call_count)) or
        steps_value < 0.0 or steps_value > 5.0 or @trunc(group_value) != group_value or
        @trunc(rows_value) != rows_value or @trunc(columns_value) != columns_value or
        @trunc(calls_value) != calls_value or @trunc(steps_value) != steps_value) return -1;
    const group_count: usize = @intFromFloat(group_value);
    const rows: usize = @intFromFloat(rows_value);
    const columns: usize = @intFromFloat(columns_value);
    const call_count: usize = @intFromFloat(calls_value);
    const ns_steps: usize = @intFromFloat(steps_value);
    const matrix_elements = rows * columns;
    if (matrix_elements > max_matrix_elements or group_count * matrix_elements > max_group_matrix_elements or
        call_count < group_count) return -1;
    if (input_length != 7 + call_count * (1 + 2 * matrix_elements) or input_length > max_valid_input_length) return -1;
    const learning_rate = values[5];
    const momentum = values[6];
    if (learning_rate < 0.0 or learning_rate > 0.25 or momentum < 0.0 or momentum > 0.99) return -1;

    var ids = [_]usize{0} ** max_call_count;
    var event_params = [_]f64{0.0} ** (max_call_count * max_matrix_elements);
    var event_gradients = [_]f64{0.0} ** (max_call_count * max_matrix_elements);
    var seen = [_]bool{false} ** max_group_count;
    var cursor: usize = 7;
    for (0..call_count) |event| {
        const id_value = values[cursor];
        if (id_value < 0.0 or id_value >= @as(f64, @floatFromInt(group_count)) or @trunc(id_value) != id_value) return -1;
        const id: usize = @intFromFloat(id_value);
        ids[event] = id;
        seen[id] = true;
        cursor += 1;
        for (0..matrix_elements) |element| {
            const value = values[cursor + element];
            if (value < -10.0 or value > 10.0) return -1;
            event_params[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
        for (0..matrix_elements) |element| {
            const value = values[cursor + element];
            if (value < -0.01 or value > 0.01) return -1;
            event_gradients[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
    }
    for (0..group_count) |id| {
        if (!seen[id]) return -1;
    }
    const group_elements = group_count * matrix_elements;
    const output_elements = 2 * group_elements;
    const out = output orelse return -2;
    if (output_capacity < output_elements) return -2;
    var velocities = [_]f64{0.0} ** max_group_matrix_elements;
    var last_params = [_]f64{0.0} ** max_group_matrix_elements;
    for (0..call_count) |event| {
        const id = ids[event];
        const state_offset = id * matrix_elements;
        const orthogonalized = orthogonalize(&event_gradients[event * matrix_elements], rows, columns, ns_steps);
        for (0..matrix_elements) |element| {
            const state_index = state_offset + element;
            const event_index = event * matrix_elements + element;
            velocities[state_index] = momentum * velocities[state_index] + orthogonalized[element];
            last_params[state_index] = event_params[event_index] - learning_rate * velocities[state_index];
        }
    }
    for (0..group_elements) |index| {
        out[index] = last_params[index];
        out[group_elements + index] = velocities[index];
    }
    return @intCast(output_elements);
}
