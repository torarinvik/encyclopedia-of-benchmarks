const MAX_PROFILE_ITEMS: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 4 * MAX_PROFILE_ITEMS;
const MAX_RATING_MILLI: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -2.0;

#[no_mangle]
pub unsafe extern "C" fn collaborative_filtering_pearson_similarity(
    values: *const i64,
    length: usize,
) -> f64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let first_count_value = values[0];
    if !(0..=MAX_PROFILE_ITEMS as i64).contains(&first_count_value) {
        return INVALID_RESULT;
    }
    let first_count = first_count_value as usize;
    let second_count_position = 1 + 2 * first_count;
    if second_count_position >= length {
        return INVALID_RESULT;
    }
    let second_count_value = values[second_count_position];
    if !(0..=MAX_PROFILE_ITEMS as i64).contains(&second_count_value) {
        return INVALID_RESULT;
    }
    let second_count = second_count_value as usize;
    if length != second_count_position + 1 + 2 * second_count {
        return INVALID_RESULT;
    }

    let mut first_ids = [0_i64; MAX_PROFILE_ITEMS];
    let mut second_ids = [0_i64; MAX_PROFILE_ITEMS];
    let mut first_ratings = [0.0_f64; MAX_PROFILE_ITEMS];
    let mut second_ratings = [0.0_f64; MAX_PROFILE_ITEMS];
    for index in 0..first_count {
        let item_id = values[1 + 2 * index];
        let rating_milli = values[2 + 2 * index];
        if !(0..=127).contains(&item_id)
            || !(-MAX_RATING_MILLI..=MAX_RATING_MILLI).contains(&rating_milli)
            || first_ids[..index].contains(&item_id)
        {
            return INVALID_RESULT;
        }
        first_ids[index] = item_id;
        first_ratings[index] = rating_milli as f64 / 1000.0;
    }
    let second_start = second_count_position + 1;
    for index in 0..second_count {
        let item_id = values[second_start + 2 * index];
        let rating_milli = values[second_start + 2 * index + 1];
        if !(0..=127).contains(&item_id)
            || !(-MAX_RATING_MILLI..=MAX_RATING_MILLI).contains(&rating_milli)
            || second_ids[..index].contains(&item_id)
        {
            return INVALID_RESULT;
        }
        second_ids[index] = item_id;
        second_ratings[index] = rating_milli as f64 / 1000.0;
    }

    let mut common_first = [0.0_f64; MAX_PROFILE_ITEMS];
    let mut common_second = [0.0_f64; MAX_PROFILE_ITEMS];
    let mut common_count = 0;
    for first in 0..first_count {
        for second in 0..second_count {
            if first_ids[first] == second_ids[second] {
                common_first[common_count] = first_ratings[first];
                common_second[common_count] = second_ratings[second];
                common_count += 1;
                break;
            }
        }
    }
    if common_count == 0 {
        return 0.0;
    }

    let mut average_first = 0.0;
    let mut average_second = 0.0;
    for index in 0..common_count {
        average_first += common_first[index];
        average_second += common_second[index];
    }
    average_first /= common_count as f64;
    average_second /= common_count as f64;

    let mut numerator = 0.0;
    let mut sum_square_first = 0.0;
    let mut sum_square_second = 0.0;
    for index in 0..common_count {
        let difference_first = common_first[index] - average_first;
        let difference_second = common_second[index] - average_second;
        numerator += difference_first * difference_second;
        sum_square_first += difference_first * difference_first;
        sum_square_second += difference_second * difference_second;
    }
    let denominator = (sum_square_first * sum_square_second).sqrt();
    if denominator.abs() < 1.0e-10 {
        0.0
    } else {
        numerator / denominator
    }
}
