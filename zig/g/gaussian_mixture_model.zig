const MAX_SAMPLES: usize = 16;
const MAX_INPUT_LENGTH: usize = 19;
const PI: f64 = 3.14159265358979323846264338327950288;

fn gaussianMixturePdf(value: f64, mean: f64, variance: f64) f64 {
    const difference = value - mean;
    return @exp(-(difference * difference) / (2.0 * variance)) / @sqrt(2.0 * PI * variance);
}

export fn gaussian_mixture_model(values: ?[*]const i64, length: usize,
                                 output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?;
    const count_value = input[0];
    const max_iterations = input[1];
    const tolerance_micro = input[2];
    if (count_value < 2 or count_value > MAX_SAMPLES or max_iterations < 1 or max_iterations > 20
            or tolerance_micro < 1 or tolerance_micro > 1000
            or length != 3 + @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    var data: [MAX_SAMPLES]f64 = undefined;
    var previous_sample: i64 = -5001;
    for (0..count) |index| {
        const sample = input[3 + index];
        if (sample < -5000 or sample > 5000 or sample < previous_sample) return -1;
        previous_sample = sample;
        data[index] = @as(f64, @floatFromInt(sample)) / 1000.0;
    }
    const required = count + 1;
    if (output == null or capacity < required) return -2;
    const result = output.?;

    var data_mean: f64 = 0;
    for (0..count) |index| data_mean += data[index];
    data_mean /= @as(f64, @floatFromInt(count));
    var variance: f64 = 0;
    for (0..count) |index| {
        const difference = data[index] - data_mean;
        variance += difference * difference;
    }
    variance = variance / @as(f64, @floatFromInt(count - 1)) + 1e-6;
    var weights = [_]f64{0.5, 0.5};
    var means = [_]f64{data[0], data[count - 1]};
    var variances = [_]f64{variance, variance};
    var responsibilities: [2][MAX_SAMPLES]f64 = undefined;
    const tolerance = @as(f64, @floatFromInt(tolerance_micro)) / 1_000_000.0;
    var previous_likelihood: f64 = 0;
    var has_previous_likelihood = false;
    var iterations: usize = 0;

    for (0..@as(usize, @intCast(max_iterations))) |iteration| {
        var component_counts = [_]f64{0, 0};
        for (0..count) |index| {
            const probability0 = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0]);
            const probability1 = weights[1] * gaussianMixturePdf(data[index], means[1], variances[1]);
            const total = probability0 + probability1;
            if (total == 0.0) return -1;
            responsibilities[0][index] = probability0 / total;
            responsibilities[1][index] = probability1 / total;
            component_counts[0] += responsibilities[0][index];
            component_counts[1] += responsibilities[1][index];
        }
        if (component_counts[0] <= 0.0 or component_counts[1] <= 0.0) return -1;
        for (0..2) |component| {
            weights[component] = component_counts[component] / @as(f64, @floatFromInt(count));
            var weighted_sum: f64 = 0;
            for (0..count) |index| weighted_sum += responsibilities[component][index] * data[index];
            means[component] = weighted_sum / component_counts[component];
            var covariance: f64 = 0;
            for (0..count) |index| {
                const difference = data[index] - means[component];
                covariance += responsibilities[component][index] * difference * difference;
            }
            variances[component] = covariance / component_counts[component] + 1e-6;
        }
        var likelihood: f64 = 0;
        for (0..count) |index| {
            const density = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0])
                + weights[1] * gaussianMixturePdf(data[index], means[1], variances[1]);
            likelihood += @log(density + 1e-12);
        }
        iterations = iteration + 1;
        if (has_previous_likelihood and @abs(likelihood - previous_likelihood) < tolerance) break;
        previous_likelihood = likelihood;
        has_previous_likelihood = true;
    }
    result[0] = @intCast(iterations);
    for (0..count) |index| {
        const probability0 = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0]);
        const probability1 = weights[1] * gaussianMixturePdf(data[index], means[1], variances[1]);
        result[index + 1] = if (probability0 >= probability1) 0 else 1;
    }
    return @intCast(required);
}
