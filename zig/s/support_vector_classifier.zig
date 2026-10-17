const MAX_N: usize = 8;
const MAX_D: usize = 4;
const MAX_Q: usize = 16;
const MAX_INPUT_VALUES: usize = 108;

fn kernelValue(left: []const f64, right: []const f64, kind: i64) f64 {
    if (kind == 0) {
        var total: f64 = 0.0;
        for (0..left.len) |i| total += left[i] * right[i];
        return total;
    }
    var normSquared: f64 = 0.0;
    for (0..left.len) |i| {
        const difference = left[i] - right[i];
        normSquared += difference * difference;
    }
    return @exp(-normSquared);
}

fn fitPredict(
    labels: *const [MAX_N]f64,
    training: *const [MAX_N * MAX_D]f64,
    testing: *const [MAX_Q * MAX_D]f64,
    n: usize,
    dimension: usize,
    queryCount: usize,
    kind: i64,
) i64 {
    var kernelMatrix: [MAX_N][MAX_N]f64 = [_][MAX_N]f64{[_]f64{0.0} ** MAX_N} ** MAX_N;
    for (0..n) |i| {
        for (0..n) |j| {
            kernelMatrix[i][j] = kernelValue(
                training.*[i * MAX_D .. i * MAX_D + dimension],
                training.*[j * MAX_D .. j * MAX_D + dimension],
                kind,
            );
        }
    }

    var optimum: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    for (0..n) |i| optimum[i] = 0.5;
    for (0..5000) |iteration| {
        var gradient: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
        for (0..n) |i| {
            var total: f64 = 0.0;
            for (0..n) |j| total += optimum[j] * labels.*[j] * kernelMatrix[i][j];
            gradient[i] = labels.*[i] * total - 1.0;
        }
        const oldOptimum = optimum;
        const learningRate = 0.1 / (1.0 + @as(f64, @floatFromInt(iteration)) / 1000.0);
        for (0..n) |i| optimum[i] = @max(0.0, @min(1.0, optimum[i] - learningRate * gradient[i]));

        var sumLabelLambda: f64 = 0.0;
        for (0..n) |i| sumLabelLambda += optimum[i] * labels.*[i];
        var correction = sumLabelLambda / @as(f64, @floatFromInt(n));
        for (0..10) |_| {
            for (0..n) |i| optimum[i] = @max(0.0, @min(1.0, optimum[i] - correction * labels.*[i]));
            sumLabelLambda = 0.0;
            for (0..n) |i| sumLabelLambda += optimum[i] * labels.*[i];
            correction = sumLabelLambda / @as(f64, @floatFromInt(n));
            if (@abs(sumLabelLambda) < 1e-10) break;
        }
        var differenceSquared: f64 = 0.0;
        for (0..n) |i| {
            const difference = optimum[i] - oldOptimum[i];
            differenceSquared += difference * difference;
        }
        if (@sqrt(differenceSquared) < 1e-8) break;
    }

    var offsetTotal: f64 = 0.0;
    var offsetCount: usize = 0;
    for (0..n) |i| {
        if (optimum[i] > 1e-5 and optimum[i] < 1.0 - 1e-5) {
            var kernelSum: f64 = 0.0;
            for (0..n) |j| {
                kernelSum += optimum[j] * labels.*[j] * kernelValue(
                    training.*[j * MAX_D .. j * MAX_D + dimension],
                    training.*[i * MAX_D .. i * MAX_D + dimension],
                    kind,
                );
            }
            offsetTotal += labels.*[i] - kernelSum;
            offsetCount += 1;
        }
    }
    if (offsetCount == 0) {
        for (0..n) |i| {
            var kernelSum: f64 = 0.0;
            for (0..n) |j| {
                kernelSum += optimum[j] * labels.*[j] * kernelValue(
                    training.*[j * MAX_D .. j * MAX_D + dimension],
                    training.*[i * MAX_D .. i * MAX_D + dimension],
                    kind,
                );
            }
            offsetTotal += labels.*[i] - kernelSum;
        }
        offsetTotal /= @as(f64, @floatFromInt(n));
    } else {
        offsetTotal /= @as(f64, @floatFromInt(offsetCount));
    }

    var mask: i64 = 0;
    for (0..queryCount) |i| {
        var total: f64 = 0.0;
        for (0..n) |j| {
            total += optimum[j] * labels.*[j] * kernelValue(
                training.*[j * MAX_D .. j * MAX_D + dimension],
                testing.*[i * MAX_D .. i * MAX_D + dimension],
                kind,
            );
        }
        if (total + offsetTotal >= 0.0) mask |= @as(i64, 1) << @intCast(i);
    }
    return mask;
}

export fn support_vector_classifier(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_VALUES + 1) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > 8 or values[1] < 1 or values[1] > 4 or
        values[2] < 0 or values[2] > 1 or values[3] < 1 or values[3] > 16) return -1;
    const n: usize = @intCast(values[0]);
    const dimension: usize = @intCast(values[1]);
    const kind = values[2];
    const queryCount: usize = @intCast(values[3]);
    if (length != 4 + n + n * dimension + queryCount * dimension) return -1;

    var labels: [MAX_N]f64 = [_]f64{0.0} ** MAX_N;
    var saw_negative = false;
    var saw_positive = false;
    for (0..n) |i| {
        const label = values[4 + i];
        if (label != -1 and label != 1) return -1;
        labels[i] = @floatFromInt(label);
        if (label < 0) {
            saw_negative = true;
        } else {
            saw_positive = true;
        }
    }
    if (!saw_negative or !saw_positive) return -1;

    var training: [MAX_N * MAX_D]f64 = [_]f64{0.0} ** (MAX_N * MAX_D);
    var testing: [MAX_Q * MAX_D]f64 = [_]f64{0.0} ** (MAX_Q * MAX_D);
    const trainingStart = 4 + n;
    for (0..n) |i| {
        for (0..dimension) |j| {
            const value = values[trainingStart + i * dimension + j];
            if (value < -4 or value > 4) return -1;
            training[i * MAX_D + j] = @floatFromInt(value);
        }
    }
    const testingStart = trainingStart + n * dimension;
    for (0..queryCount) |i| {
        for (0..dimension) |j| {
            const value = values[testingStart + i * dimension + j];
            if (value < -4 or value > 4) return -1;
            testing[i * MAX_D + j] = @floatFromInt(value);
        }
    }
    return fitPredict(&labels, &training, &testing, n, dimension, queryCount, kind);
}
