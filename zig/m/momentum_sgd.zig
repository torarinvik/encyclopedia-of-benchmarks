const std = @import("std");

const MAX_GROUP_COUNT: usize = 8;
const MAX_VECTOR_LENGTH: usize = 16;
const MAX_GROUP_VECTOR_ELEMENTS: usize = 32;
const MAX_CALL_COUNT: usize = 8;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 270;

export fn momentum_sgd(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 5 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const group_value = input[0];
    const vector_value = input[1];
    const calls_value = input[2];
    if (!std.math.isFinite(group_value) or group_value < 1.0 or group_value > @as(f64, @floatFromInt(MAX_GROUP_COUNT))) return -1;
    if (!std.math.isFinite(vector_value) or vector_value < 1.0 or vector_value > @as(f64, @floatFromInt(MAX_VECTOR_LENGTH))) return -1;
    if (!std.math.isFinite(calls_value) or calls_value < 1.0 or calls_value > @as(f64, @floatFromInt(MAX_CALL_COUNT))) return -1;
    const group_count: usize = @intFromFloat(group_value);
    const vector_length: usize = @intFromFloat(vector_value);
    const call_count: usize = @intFromFloat(calls_value);
    if (group_value != @as(f64, @floatFromInt(group_count)) or
        vector_value != @as(f64, @floatFromInt(vector_length)) or
        calls_value != @as(f64, @floatFromInt(call_count))) return -1;
    if (group_count * vector_length > MAX_GROUP_VECTOR_ELEMENTS or call_count < group_count) return -1;
    if (input_length != 5 + call_count * (1 + 2 * vector_length)) return -1;

    const learning_rate = input[3];
    const momentum = input[4];
    if (!std.math.isFinite(learning_rate) or learning_rate < 1e-6 or learning_rate > 1.0) return -1;
    if (!std.math.isFinite(momentum) or momentum < 0.0 or momentum > 0.99) return -1;

    var ids = [_]usize{0} ** MAX_CALL_COUNT;
    var event_params = [_]f64{0.0} ** (MAX_CALL_COUNT * MAX_VECTOR_LENGTH);
    var event_gradients = [_]f64{0.0} ** (MAX_CALL_COUNT * MAX_VECTOR_LENGTH);
    var seen = [_]bool{false} ** MAX_GROUP_COUNT;
    var cursor: usize = 5;
    for (0..call_count) |event| {
        const id_value = input[cursor];
        if (!std.math.isFinite(id_value) or id_value < 0.0 or id_value >= @as(f64, @floatFromInt(group_count))) return -1;
        const id: usize = @intFromFloat(id_value);
        if (id_value != @as(f64, @floatFromInt(id))) return -1;
        ids[event] = id;
        seen[id] = true;
        cursor += 1;
        for (0..vector_length) |component| {
            const value = input[cursor + component];
            if (!std.math.isFinite(value) or value < -1000.0 or value > 1000.0) return -1;
            event_params[event * vector_length + component] = value;
        }
        cursor += vector_length;
        for (0..vector_length) |component| {
            const value = input[cursor + component];
            if (!std.math.isFinite(value) or value < -1000.0 or value > 1000.0) return -1;
            event_gradients[event * vector_length + component] = value;
        }
        cursor += vector_length;
    }
    for (0..group_count) |id| {
        if (!seen[id]) return -1;
    }
    const group_elements = group_count * vector_length;
    if (output == null or output_capacity < 2 * group_elements) return -2;

    var velocities = [_]f64{0.0} ** MAX_GROUP_VECTOR_ELEMENTS;
    var last_params = [_]f64{0.0} ** MAX_GROUP_VECTOR_ELEMENTS;
    for (0..call_count) |event| {
        const id = ids[event];
        for (0..vector_length) |component| {
            const state_index = id * vector_length + component;
            const event_index = event * vector_length + component;
            const updated_velocity = momentum * velocities[state_index] - learning_rate * event_gradients[event_index];
            velocities[state_index] = updated_velocity;
            last_params[state_index] = event_params[event_index] + updated_velocity;
        }
    }
    for (0..group_elements) |index| {
        output[index] = last_params[index];
        output[group_elements + index] = velocities[index];
    }
    return @intCast(2 * group_elements);
}
