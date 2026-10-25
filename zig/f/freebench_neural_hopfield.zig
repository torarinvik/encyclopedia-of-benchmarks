const PATTERN_COUNT: usize = 10;
const MAX_NEURONS: usize = 8;

fn activation(value: f32) f32 {
    const x = @as(f64, value);
    const bounded = @min(200.0, @max(-200.0, x));
    const e = @exp(-bounded);
    return @floatCast((1.0 - e) / (1.0 + e));
}

fn runCont(weights: []const f32, source: []const i64, dest: []i64) bool {
    const neurons = source.len;
    var temp_a = [_]f32{0} ** MAX_NEURONS;
    var temp_c = [_]i64{0} ** MAX_NEURONS;
    for (0..neurons) |neuron| {
        dest[neuron] = source[neuron];
        temp_a[neuron] = @floatFromInt(source[neuron]);
    }
    var stable = false;
    var threshold = false;
    var iterations: usize = 0;
    while (!stable and iterations < 500) {
        var threshold_iterations: usize = 0;
        for (0..neurons) |row| {
            var sum: f32 = 0;
            for (0..neurons) |neuron| sum += weights[row * neurons + neuron] * @as(f32, @floatFromInt(source[neuron]));
            temp_a[row] = activation(sum);
        }
        while (!threshold and threshold_iterations < 50) {
            threshold = true;
            for (0..neurons) |row| {
                if (@abs(temp_a[row]) < 0.7) {
                    var sum: f32 = 0;
                    for (0..neurons) |neuron| sum += weights[row * neurons + neuron] * temp_a[neuron];
                    temp_a[row] = activation(sum);
                    if (temp_a[row] < 0.7) threshold = false;
                }
            }
            threshold_iterations += 1;
        }
        var same = true;
        for (0..neurons) |neuron| {
            temp_c[neuron] = if (temp_a[neuron] > 0) 1 else -1;
            if (dest[neuron] != temp_c[neuron]) same = false;
        }
        if (same) stable = true else {
            for (0..neurons) |neuron| {
                if (dest[neuron] != temp_c[neuron]) {
                    dest[neuron] = temp_c[neuron];
                    break;
                }
            }
            for (0..neurons) |neuron| temp_a[neuron] = @floatFromInt(dest[neuron]);
        }
        iterations += 1;
    }
    return iterations < 500;
}

export fn freebench_neural_hopfield(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 94) return -1;
    const width = input[0];
    const height = input[1];
    const pattern_count = input[2];
    if (width < 1 or width > 8 or height < 1 or height > 8 or pattern_count != PATTERN_COUNT) return -1;
    const neurons: usize = @intCast(width * height);
    if (neurons < 2 or neurons > MAX_NEURONS or length != 3 + PATTERN_COUNT * (1 + neurons)) return -1;

    var patterns = [_]i64{0} ** (PATTERN_COUNT * MAX_NEURONS);
    var offset: usize = 3;
    for (0..PATTERN_COUNT) |pattern| {
        const label = input[offset];
        offset += 1;
        if (label < 65 or label > 90) return -1;
        for (0..neurons) |neuron| {
            const cell = input[offset];
            offset += 1;
            if (cell != -1 and cell != 1) return -1;
            patterns[pattern * MAX_NEURONS + neuron] = cell;
            if (pattern != 0 and cell != patterns[neuron]) return -1;
        }
    }

    var hamming_warnings: usize = 0;
    for (0..PATTERN_COUNT) |first| {
        for (first + 1..PATTERN_COUNT) |second| {
            var normal: usize = 0;
            var complement: usize = 0;
            for (0..neurons) |neuron| {
                if (patterns[first * MAX_NEURONS + neuron] != patterns[second * MAX_NEURONS + neuron]) normal += 1;
                if (patterns[first * MAX_NEURONS + neuron] != -patterns[second * MAX_NEURONS + neuron]) complement += 1;
            }
            if (normal < 2) hamming_warnings += 1;
            if (complement < 2) hamming_warnings += 1;
        }
    }
    _ = hamming_warnings;

    var weights = [_]f32{0} ** (MAX_NEURONS * MAX_NEURONS);
    for (0..PATTERN_COUNT) |pattern| {
        for (0..neurons) |row| {
            for (0..neurons) |column| {
                if (row == column) weights[row * neurons + column] = 0
                else weights[row * neurons + column] += @floatFromInt(patterns[pattern * MAX_NEURONS + row] * patterns[pattern * MAX_NEURONS + column]);
            }
        }
    }

    var converged = false;
    for (0..1) |_| {
        var status = true;
        for (0..PATTERN_COUNT) |pattern| {
            const base = pattern * MAX_NEURONS;
            var recalled = [_]i64{0} ** MAX_NEURONS;
            if (!runCont(weights[0 .. neurons * neurons], patterns[base .. base + neurons], recalled[0..neurons])) return -2;
            var correction = [_]f32{0} ** MAX_NEURONS;
            for (0..neurons) |neuron| {
                correction[neuron] = @as(f32, @floatFromInt(patterns[base + neuron] - recalled[neuron])) * 0.5;
                if (correction[neuron] != 0) status = false;
            }
            for (0..neurons) |row| {
                for (0..neurons) |column| {
                    if (row == column) weights[row * neurons + column] = 0
                    else weights[row * neurons + column] += correction[row] * @as(f32, @floatFromInt(patterns[base + column]));
                }
            }
        }
        if (status) converged = true;
    }
    if (!converged) return -2;

    var stored_count: i64 = 0;
    for (0..PATTERN_COUNT) |pattern| {
        const base = pattern * MAX_NEURONS;
        var recalled = [_]i64{0} ** MAX_NEURONS;
        if (!runCont(weights[0 .. neurons * neurons], patterns[base .. base + neurons], recalled[0..neurons])) return -2;
        var stored = true;
        for (0..neurons) |neuron| if (patterns[base + neuron] != recalled[neuron]) { stored = false; };
        if (stored) stored_count += 1;
    }
    return stored_count;
}
