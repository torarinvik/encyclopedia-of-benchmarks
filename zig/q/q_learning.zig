const std = @import("std");

const MAX_PARSEABLE_INPUT_LENGTH: usize = 11;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn q_learning_update(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 6 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (!exactInteger(values[0], 0, 1) or !exactInteger(values[5], 0, 4)) return -1;
    const done = values[0] == 1.0;
    const alpha = values[1];
    const gamma = values[2];
    const reward = values[3];
    const old_q = values[4];
    const next_action_count: usize = @intFromFloat(values[5]);
    if (input_length != 6 + next_action_count) return -1;
    if (!std.math.isFinite(alpha) or alpha < 0 or alpha > 1 or
        !std.math.isFinite(gamma) or gamma < 0 or gamma > 1 or
        !std.math.isFinite(reward) or reward < -100 or reward > 100 or
        !std.math.isFinite(old_q) or old_q < -100 or old_q > 100) return -1;
    for (0..next_action_count) |index| {
        const value = values[6 + index];
        if (!std.math.isFinite(value) or value < -100 or value > 100) return -1;
    }

    var max_q_next: f64 = 0;
    if (!done and next_action_count > 0) {
        max_q_next = values[6];
        for (1..next_action_count) |index| {
            if (values[6 + index] > max_q_next) max_q_next = values[6 + index];
        }
    }
    const updated = (1.0 - alpha) * old_q + alpha * (reward + gamma * max_q_next);
    if (!std.math.isFinite(updated)) return -1;
    const out = output orelse return -2;
    if (capacity < 1) return -2;
    out[0] = updated;
    return 1;
}
