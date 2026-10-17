const MAX_PARSEABLE_INPUT_LENGTH: usize = 45;
const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_FEATURE_VALUES: usize = MAX_SAMPLES * MAX_FEATURES;

export fn linear_regression_vectorized(input: [*c]const f64, length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const sample_value = input[0];
    const feature_value = input[1];
    const iteration_value = input[2];
    if (!(sample_value >= 2.0 and sample_value <= @as(f64, MAX_SAMPLES)) or
        !(feature_value >= 2.0 and feature_value <= @as(f64, MAX_FEATURES)) or
        !(iteration_value >= 10.0 and iteration_value <= 128.0)) return -1;
    const sample_count: usize = @intFromFloat(sample_value);
    const feature_count: usize = @intFromFloat(feature_value);
    const iterations: usize = @intFromFloat(iteration_value);
    if (@as(f64, @floatFromInt(sample_count)) != sample_value or
        @as(f64, @floatFromInt(feature_count)) != feature_value or
        @as(f64, @floatFromInt(iterations)) != iteration_value) return -1;
    if (length != 4 + sample_count * feature_count + sample_count) return -1;

    const alpha = input[3];
    if (!(alpha >= 0.0001 and alpha <= 0.01)) return -1;

    var features: [MAX_FEATURE_VALUES]f64 = @splat(0.0);
    var labels: [MAX_SAMPLES]f64 = @splat(0.0);
    const feature_values = sample_count * feature_count;
    for (0..feature_values) |index| {
        const value = input[4 + index];
        if (!(value >= -1.0 and value <= 1.0)) return -1;
        features[index] = value;
    }
    for (0..sample_count) |row| {
        if (features[row * feature_count] != 1.0) return -1;
    }
    for (0..sample_count) |row| {
        const value = input[4 + feature_values + row];
        if (!(value >= -1.0 and value <= 1.0)) return -1;
        labels[row] = value;
    }
    if (output == null or output_capacity < feature_count) return -2;

    var theta: [MAX_FEATURES]f64 = @splat(0.0);
    var errors: [MAX_SAMPLES]f64 = @splat(0.0);
    var gradients: [MAX_FEATURES]f64 = @splat(0.0);
    for (0..iterations) |_| {
        for (0..sample_count) |row| {
            var prediction: f64 = 0.0;
            for (0..feature_count) |column|
                prediction += features[row * feature_count + column] * theta[column];
            errors[row] = prediction - labels[row];
        }
        for (0..feature_count) |column| {
            var gradient: f64 = 0.0;
            for (0..sample_count) |row|
                gradient += features[row * feature_count + column] * errors[row];
            gradients[column] = gradient / @as(f64, @floatFromInt(sample_count));
        }
        for (0..feature_count) |column| theta[column] -= alpha * gradients[column];
    }
    for (0..feature_count) |column| output[column] = theta[column];
    return @intCast(feature_count);
}
