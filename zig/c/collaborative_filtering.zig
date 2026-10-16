const max_users: usize = 65;
const max_input_length: usize = 1 + 4 * max_users;
const max_similarity_ticks: i64 = 1_000_000_000_000;
const max_rating_milli: i64 = 1_000_000_000;
const invalid_result: f64 = -1.0e300;

export fn collaborative_filtering(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 1 or length > max_input_length) return invalid_result;
    const count_value = values[0];
    if (count_value < 1 or count_value > @as(i64, @intCast(max_users))) return invalid_result;
    const count: usize = @intCast(count_value);
    if (length != 1 + 4 * count) return invalid_result;

    var total_similarity: f64 = 0.0;
    var weighted_sum: f64 = 0.0;
    var target_user_count: usize = 0;
    for (0..count) |index| {
        const offset = 1 + 4 * index;
        const is_target_user = values[offset];
        const has_target_rating = values[offset + 1];
        const similarity_ticks = values[offset + 2];
        const rating_milli = values[offset + 3];
        if ((is_target_user != 0 and is_target_user != 1)
            or (has_target_rating != 0 and has_target_rating != 1)
            or similarity_ticks < -max_similarity_ticks or similarity_ticks > max_similarity_ticks
            or rating_milli < -max_rating_milli or rating_milli > max_rating_milli)
            return invalid_result;
        if (is_target_user == 1) {
            target_user_count += 1;
            continue;
        }
        if (has_target_rating == 0) continue;
        const similarity = @as(f64, @floatFromInt(similarity_ticks)) / 1_000_000_000_000.0;
        const rating = @as(f64, @floatFromInt(rating_milli)) / 1000.0;
        total_similarity += if (similarity < 0.0) -similarity else similarity;
        weighted_sum += similarity * rating;
    }
    if (target_user_count != 1) return invalid_result;
    return if (total_similarity < 1.0e-10) 0.0 else weighted_sum / total_similarity;
}
