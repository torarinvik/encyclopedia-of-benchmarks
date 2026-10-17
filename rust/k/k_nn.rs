const MAX_INPUT_VALUES: usize = 300;
const MAX_TRAINING_COUNT: usize = 32;
const MAX_FEATURE_COUNT: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn k_nn(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES { return -1; }
    let training_value = *input;
    let feature_value = *input.add(1);
    let neighbor_value = *input.add(2);
    if !(1..=MAX_TRAINING_COUNT as i64).contains(&training_value)
        || !(1..=MAX_FEATURE_COUNT as i64).contains(&feature_value) { return -1; }
    let training_count = training_value as usize;
    let feature_count = feature_value as usize;
    if neighbor_value < 1 || neighbor_value > training_value || neighbor_value % 2 == 0 { return -1; }
    let neighbor_count = neighbor_value as usize;
    let feature_start = 3;
    let label_start = feature_start + training_count * feature_count;
    let query_start = label_start + training_count;
    let expected_length = query_start + feature_count;
    if length != expected_length { return -1; }

    for index in 0..training_count * feature_count {
        let value = *input.add(feature_start + index);
        if !(-32..=32).contains(&value) { return -1; }
    }
    for row in 0..training_count {
        let label = *input.add(label_start + row);
        if label != 0 && label != 1 { return -1; }
    }
    for feature in 0..feature_count {
        let value = *input.add(query_start + feature);
        if !(-32..=32).contains(&value) { return -1; }
    }

    let mut query_norm = 0_i64;
    for feature in 0..feature_count {
        let query = *input.add(query_start + feature);
        query_norm += query * query;
    }
    let mut distances = [0_i64; MAX_TRAINING_COUNT];
    let mut order = [0_usize; MAX_TRAINING_COUNT];
    for row in 0..training_count {
        let mut row_norm = 0_i64;
        let mut cross_product = 0_i64;
        for feature in 0..feature_count {
            let coordinate = *input.add(feature_start + row * feature_count + feature);
            let query = *input.add(query_start + feature);
            row_norm += coordinate * coordinate;
            cross_product += coordinate * query;
        }
        distances[row] = query_norm - 2 * cross_product + row_norm;
        order[row] = row;
    }
    for row in 0..training_count {
        for other in row + 1..training_count {
            if distances[row] == distances[other] { return -1; }
        }
    }
    for position in 1..training_count {
        let row = order[position];
        let mut cursor = position;
        while cursor > 0 && distances[order[cursor - 1]] > distances[row] {
            order[cursor] = order[cursor - 1];
            cursor -= 1;
        }
        order[cursor] = row;
    }
    let mut zero_votes = 0;
    for position in 0..neighbor_count {
        if *input.add(label_start + order[position]) == 0 { zero_votes += 1; }
    }
    if zero_votes > neighbor_count / 2 { 0 } else { 1 }
}
