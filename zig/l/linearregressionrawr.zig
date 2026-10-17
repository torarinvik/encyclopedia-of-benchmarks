const std = @import("std");

const MIN_SAMPLE_COUNT: usize = 2;
const MAX_SAMPLE_COUNT: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 66;
const MAX_OUTPUT_ELEMENTS: usize = 2;

fn exactIntegerInRange(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and value >= minimum and value <= maximum and @trunc(value) == value;
}

fn roundedDivide(numerator: f64, denominator: f64) f64 {
    return numerator / denominator;
}

export fn linearregressionrawr(
    input: ?[*]const f64,
    input_length: usize,
    output: ?[*]f64,
    output_capacity: usize,
) i64 {
    if (input == null or input_length == 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    for (values) |value| {
        if (!std.math.isFinite(value)) return -1;
    }

    if (!exactIntegerInRange(values[0], @floatFromInt(MIN_SAMPLE_COUNT), @floatFromInt(MAX_SAMPLE_COUNT))) return -1;
    const sample_count: usize = @intFromFloat(values[0]);
    if (input_length != 1 + 2 * sample_count) return -1;

    var predictor_sum: i64 = 0;
    var response_sum: i64 = 0;
    var cross_product_sum: i64 = 0;
    var predictor_square_sum: i64 = 0;
    var first_predictor: i64 = 0;
    var predictors_are_constant = true;

    for (0..sample_count) |index| {
        const predictor_value = values[1 + index];
        const response_value = values[1 + sample_count + index];
        if (!exactIntegerInRange(predictor_value, -4, 4) or
            !exactIntegerInRange(response_value, -16, 16)) return -1;

        const predictor: i64 = @intFromFloat(predictor_value);
        const response: i64 = @intFromFloat(response_value);
        if (index == 0) {
            first_predictor = predictor;
        } else if (predictor != first_predictor) {
            predictors_are_constant = false;
        }

        predictor_sum += predictor;
        response_sum += response;
        cross_product_sum += predictor * response;
        predictor_square_sum += predictor * predictor;
    }

    if (predictor_sum != 0 or predictors_are_constant or predictor_square_sum == 0) return -1;

    const staged = [_]f64{
        roundedDivide(@floatFromInt(response_sum), @floatFromInt(sample_count)),
        roundedDivide(@floatFromInt(cross_product_sum), @floatFromInt(predictor_square_sum)),
    };
    const result = output orelse return -2;
    if (output_capacity < MAX_OUTPUT_ELEMENTS) return -2;
    for (0..MAX_OUTPUT_ELEMENTS) |index| result[index] = staged[index];
    return @intCast(MAX_OUTPUT_ELEMENTS);
}
