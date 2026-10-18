const MAX_INPUT_LENGTH: usize = 360;
const MAX_OUTPUT_BYTES: usize = 72;

export fn multinomial_naive_bayes_classifier(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    const fit_count_value = input[0];
    if (fit_count_value < 1 or fit_count_value > 2) return -1;
    const fit_count: usize = @intCast(fit_count_value);
    var position: usize = 1;
    var feature_width: usize = 0;
    var training_rows: i64 = 0;
    var class_counts = [_]i64{0} ** 8;
    var feature_sums = [_]f64{0.0} ** 64;
    var class_totals = [_]f64{0.0} ** 8;
    var labels = [_]i64{0} ** 16;
    var training_features = [_]i64{0} ** 128;

    for (0..fit_count) |_| {
        if (position + 2 > input_length) return -1;
        const rows_value = input[position];
        position += 1;
        const width_value = input[position];
        position += 1;
        if (rows_value < 1 or rows_value > 16 or width_value < 1 or width_value > 8) return -1;
        const rows: usize = @intCast(rows_value);
        const width: usize = @intCast(width_value);
        if (position + rows + rows * width > input_length) return -1;
        for (0..rows) |row| {
            const label = input[position];
            position += 1;
            if (label < 0 or label > 7) return -1;
            labels[row] = label;
        }
        for (0..rows) |row| {
            for (0..width) |column| {
                const count = input[position];
                position += 1;
                if (count < 0 or count > 100) return -1;
                training_features[row * 8 + column] = count;
            }
        }

        class_counts = [_]i64{0} ** 8;
        feature_sums = [_]f64{0.0} ** 64;
        class_totals = [_]f64{0.0} ** 8;
        training_rows = rows_value;
        feature_width = width;
        for (0..rows) |row| {
            const label: usize = @intCast(labels[row]);
            class_counts[label] += 1;
            for (0..width) |column| {
                const count: f64 = @floatFromInt(training_features[row * 8 + column]);
                feature_sums[label * 8 + column] += count;
                class_totals[label] += count;
            }
        }
    }

    if (position + 2 > input_length) return -1;
    const prediction_count_value = input[position];
    position += 1;
    const prediction_width_value = input[position];
    position += 1;
    if (prediction_count_value < 1 or prediction_count_value > 8 or prediction_width_value < 1 or prediction_width_value > 8) return -1;
    const prediction_count: usize = @intCast(prediction_count_value);
    const prediction_width: usize = @intCast(prediction_width_value);
    if (prediction_width != feature_width or position + prediction_count * prediction_width != input_length) return -1;
    var prediction_features = [_]i64{0} ** 64;
    for (0..prediction_count) |row| {
        for (0..prediction_width) |column| {
            const count = input[position];
            position += 1;
            if (count < 0 or count > 100) return -1;
            prediction_features[row * 8 + column] = count;
        }
    }

    var predictions = [_]i64{0} ** 8;
    for (0..prediction_count) |row| {
        var best_score: f64 = -1.0e300;
        var second_score: f64 = -1.0e300;
        var best_label: i64 = -1;
        for (0..8) |label| {
            if (class_counts[label] == 0) continue;
            const class_count: f64 = @floatFromInt(class_counts[label]);
            const train_count: f64 = @floatFromInt(training_rows);
            var score = @log(class_count / train_count);
            const width_as_f64: f64 = @floatFromInt(feature_width);
            const denominator = class_totals[label] + width_as_f64;
            for (0..feature_width) |column| {
                const sum = feature_sums[label * 8 + column];
                const likelihood = (sum + 1.0) / denominator;
                const query_count: f64 = @floatFromInt(prediction_features[row * 8 + column]);
                score += query_count * @log(likelihood);
            }
            if (score > best_score) {
                second_score = best_score;
                best_score = score;
                best_label = @intCast(label);
            } else if (score > second_score) {
                second_score = score;
            }
        }
        if (best_label < 0 or (second_score > -1.0e299 and best_score - second_score < 1e-8)) return -1;
        predictions[row] = best_label;
    }

    const output_words = prediction_count + 1;
    const output_bytes = output_words * 8;
    if (output == null or output_capacity < output_bytes or output_bytes > MAX_OUTPUT_BYTES) return -2;
    var fields = [_]i64{0} ** 9;
    fields[0] = prediction_count_value;
    for (0..prediction_count) |index| fields[index + 1] = predictions[index];
    for (0..output_words) |index| {
        const bits: u64 = @bitCast(fields[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
