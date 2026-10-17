const MAX_INPUT_VALUES: usize = 300;
const MAX_TRAINING_COUNT: usize = 32;
const MAX_FEATURE_COUNT: usize = 8;

export fn k_nn(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > MAX_INPUT_VALUES) return -1;
    const training_value = values[0];
    const feature_value = values[1];
    const neighbor_value = values[2];
    if (training_value < 1 or training_value > @as(i64, @intCast(MAX_TRAINING_COUNT)) or
        feature_value < 1 or feature_value > @as(i64, @intCast(MAX_FEATURE_COUNT)) or
        neighbor_value < 1 or neighbor_value > training_value or neighbor_value % 2 == 0) return -1;
    const training_count: usize = @intCast(training_value);
    const feature_count: usize = @intCast(feature_value);
    const neighbor_count: usize = @intCast(neighbor_value);
    const feature_start: usize = 3;
    const label_start = feature_start + training_count * feature_count;
    const query_start = label_start + training_count;
    if (length != query_start + feature_count) return -1;
    for (0..training_count * feature_count) |i| {
        const value = values[feature_start + i];
        if (value < -32 or value > 32) return -1;
    }
    for (0..training_count) |i| if (values[label_start + i] != 0 and values[label_start + i] != 1) return -1;
    for (0..feature_count) |i| {
        const value = values[query_start + i];
        if (value < -32 or value > 32) return -1;
    }

    var query_norm: i64 = 0;
    for (0..feature_count) |feature| {
        const query = values[query_start + feature];
        query_norm += query * query;
    }
    var distances = [_]i64{0} ** MAX_TRAINING_COUNT;
    var order = [_]usize{0} ** MAX_TRAINING_COUNT;
    for (0..training_count) |row| {
        var row_norm: i64 = 0;
        var cross_product: i64 = 0;
        for (0..feature_count) |feature| {
            const coordinate = values[feature_start + row * feature_count + feature];
            const query = values[query_start + feature];
            row_norm += coordinate * coordinate;
            cross_product += coordinate * query;
        }
        distances[row] = query_norm - 2 * cross_product + row_norm;
        order[row] = row;
    }
    for (0..training_count) |row| for (row + 1..training_count) |other| {
        if (distances[row] == distances[other]) return -1;
    };
    for (1..training_count) |position| {
        const row = order[position];
        var cursor = position;
        while (cursor > 0 and distances[order[cursor - 1]] > distances[row]) {
            order[cursor] = order[cursor - 1];
            cursor -= 1;
        }
        order[cursor] = row;
    }
    var zero_votes: usize = 0;
    for (0..neighbor_count) |position| if (values[label_start + order[position]] == 0) { zero_votes += 1; };
    return if (zero_votes > neighbor_count / 2) 0 else 1;
}
