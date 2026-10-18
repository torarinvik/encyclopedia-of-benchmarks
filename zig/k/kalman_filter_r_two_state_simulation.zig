const std = @import("std");

const MAX_OBSERVATIONS: usize = 12;
const MAX_OUTPUT_ELEMENTS: usize = 30;

export fn kalman_filter_r_two_state_simulation(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (input_length < 1 or input_length > MAX_OBSERVATIONS) return -1;
    for (0..input_length) |index| {
        const value = input[index];
        if (!std.math.isFinite(value) or value < -1000.0 or value > 1000.0) return -1;
    }

    const required = 2 * input_length + 6;
    if (required > MAX_OUTPUT_ELEMENTS) return -1;
    var staged = [_]f64{0.0} ** MAX_OUTPUT_ELEMENTS;
    var state_0 = input[0];
    var state_1: f64 = 0.0;
    var covariance_00: f64 = 1.0;
    var covariance_01: f64 = 0.0;
    var covariance_10: f64 = 0.0;
    var covariance_11: f64 = 1.0;
    var state_pred_0: f64 = 0.0;
    var state_pred_1: f64 = 0.0;
    var covariance_pred_00: f64 = 0.0;
    var covariance_pred_01: f64 = 0.0;
    var covariance_pred_10: f64 = 0.0;
    var covariance_pred_11: f64 = 0.0;

    for (0..input_length) |step| {
        state_pred_0 = state_0;
        state_pred_1 = state_0 + state_1;

        const temp_00 = covariance_00;
        const temp_01 = covariance_01;
        const temp_10 = covariance_00 + covariance_10;
        const temp_11 = covariance_01 + covariance_11;
        covariance_pred_00 = temp_00 + 0.0001;
        covariance_pred_01 = temp_00 + temp_01;
        covariance_pred_10 = temp_10;
        covariance_pred_11 = temp_10 + temp_11 + 0.0001;

        const innovation = covariance_pred_00 + 0.1;
        const gain_0 = covariance_pred_00 / innovation;
        const gain_1 = covariance_pred_10 / innovation;
        const residual = input[step] - state_pred_0;
        state_0 = state_pred_0 + gain_0 * residual;
        state_1 = state_pred_1 + gain_1 * residual;
        staged[2 * step] = state_0;
        staged[2 * step + 1] = state_1;

        covariance_00 = (1.0 - gain_0) * covariance_pred_00 + covariance_pred_10;
        covariance_01 = (1.0 - gain_0) * covariance_pred_01 + covariance_pred_11;
        covariance_10 = (1.0 - gain_1) * covariance_pred_00 + covariance_pred_10;
        covariance_11 = (1.0 - gain_1) * covariance_pred_01 + covariance_pred_11;
    }

    var position = 2 * input_length;
    staged[position] = state_pred_0;
    staged[position + 1] = state_pred_1;
    staged[position + 2] = covariance_pred_00;
    staged[position + 3] = covariance_pred_10;
    staged[position + 4] = covariance_pred_01;
    staged[position + 5] = covariance_pred_11;
    const output = output_opt orelse return -2;
    if (output_capacity < required) return -2;
    @memcpy(output[0..required], staged[0..required]);
    return @intCast(required);
}
