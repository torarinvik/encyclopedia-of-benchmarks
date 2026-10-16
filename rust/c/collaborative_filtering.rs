const MAX_USERS: usize = 65;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_USERS;
const MAX_SIMILARITY_TICKS: i64 = 1_000_000_000_000;
const MAX_RATING_MILLI: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn collaborative_filtering(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if !(1..=MAX_USERS as i64).contains(&count_value) {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    if length != 1 + 4 * count {
        return INVALID_RESULT;
    }

    let mut total_similarity = 0.0f64;
    let mut weighted_sum = 0.0f64;
    let mut target_user_count = 0;
    for record in values[1..].chunks_exact(4) {
        let [is_target_user, has_target_rating, similarity_ticks, rating_milli] =
            [record[0], record[1], record[2], record[3]];
        if !(0..=1).contains(&is_target_user)
            || !(0..=1).contains(&has_target_rating)
            || !(-MAX_SIMILARITY_TICKS..=MAX_SIMILARITY_TICKS).contains(&similarity_ticks)
            || !(-MAX_RATING_MILLI..=MAX_RATING_MILLI).contains(&rating_milli)
        {
            return INVALID_RESULT;
        }
        if is_target_user == 1 {
            target_user_count += 1;
            continue;
        }
        if has_target_rating == 0 {
            continue;
        }
        let similarity = similarity_ticks as f64 / 1_000_000_000_000.0;
        let rating = rating_milli as f64 / 1000.0;
        total_similarity += similarity.abs();
        weighted_sum += similarity * rating;
    }
    if target_user_count != 1 {
        return INVALID_RESULT;
    }
    if total_similarity.abs() < 1.0e-10 {
        0.0
    } else {
        weighted_sum / total_similarity
    }
}
