const max_profile_items: usize = 32;
const max_input_length: usize = 2 + 4 * max_profile_items;
const max_rating_milli: i64 = 1_000_000_000;
const invalid_result: f64 = -2.0;

export fn collaborative_filtering_pearson_similarity(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > max_input_length) return invalid_result;
    const first_count_value = values[0];
    if (first_count_value < 0 or first_count_value > @as(i64, @intCast(max_profile_items)))
        return invalid_result;
    const first_count: usize = @intCast(first_count_value);
    const second_count_position = 1 + 2 * first_count;
    if (second_count_position >= length) return invalid_result;
    const second_count_value = values[second_count_position];
    if (second_count_value < 0 or second_count_value > @as(i64, @intCast(max_profile_items)))
        return invalid_result;
    const second_count: usize = @intCast(second_count_value);
    if (length != second_count_position + 1 + 2 * second_count) return invalid_result;

    var first_ids: [max_profile_items]i64 = @splat(0);
    var second_ids: [max_profile_items]i64 = @splat(0);
    var first_ratings: [max_profile_items]f64 = @splat(0.0);
    var second_ratings: [max_profile_items]f64 = @splat(0.0);
    for (0..first_count) |index| {
        const item_id = values[1 + 2 * index];
        const rating_milli = values[2 + 2 * index];
        if (item_id < 0 or item_id > 127 or rating_milli < -max_rating_milli
            or rating_milli > max_rating_milli) return invalid_result;
        for (0..index) |earlier| if (first_ids[earlier] == item_id) return invalid_result;
        first_ids[index] = item_id;
        first_ratings[index] = @as(f64, @floatFromInt(rating_milli)) / 1000.0;
    }
    const second_start = second_count_position + 1;
    for (0..second_count) |index| {
        const item_id = values[second_start + 2 * index];
        const rating_milli = values[second_start + 2 * index + 1];
        if (item_id < 0 or item_id > 127 or rating_milli < -max_rating_milli
            or rating_milli > max_rating_milli) return invalid_result;
        for (0..index) |earlier| if (second_ids[earlier] == item_id) return invalid_result;
        second_ids[index] = item_id;
        second_ratings[index] = @as(f64, @floatFromInt(rating_milli)) / 1000.0;
    }

    var common_first: [max_profile_items]f64 = @splat(0.0);
    var common_second: [max_profile_items]f64 = @splat(0.0);
    var common_count: usize = 0;
    for (0..first_count) |first| {
        for (0..second_count) |second| {
            if (first_ids[first] == second_ids[second]) {
                common_first[common_count] = first_ratings[first];
                common_second[common_count] = second_ratings[second];
                common_count += 1;
                break;
            }
        }
    }
    if (common_count == 0) return 0.0;

    var average_first: f64 = 0.0;
    var average_second: f64 = 0.0;
    for (0..common_count) |index| {
        average_first += common_first[index];
        average_second += common_second[index];
    }
    average_first /= @floatFromInt(common_count);
    average_second /= @floatFromInt(common_count);

    var numerator: f64 = 0.0;
    var sum_square_first: f64 = 0.0;
    var sum_square_second: f64 = 0.0;
    for (0..common_count) |index| {
        const difference_first = common_first[index] - average_first;
        const difference_second = common_second[index] - average_second;
        numerator += difference_first * difference_second;
        sum_square_first += difference_first * difference_first;
        sum_square_second += difference_second * difference_second;
    }
    const denominator = @sqrt(sum_square_first * sum_square_second);
    return if (denominator < 1.0e-10) 0.0 else numerator / denominator;
}
