module k_nn;

const usz MAX_PARSEABLE_INPUT_VALUES = 300;
const usz MAX_TRAINING_COUNT = 32;
const usz MAX_FEATURE_COUNT = 8;

fn long k_nn(long* input, usz input_length) @export("k_nn") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_VALUES) return -1L;

    long training_count_value = input[0];
    long feature_count_value = input[1];
    long neighbor_count_value = input[2];
    if (training_count_value < 1 || training_count_value > (long)MAX_TRAINING_COUNT ||
        feature_count_value < 1 || feature_count_value > (long)MAX_FEATURE_COUNT ||
        neighbor_count_value < 1 || neighbor_count_value > training_count_value ||
        neighbor_count_value % 2 == 0) return -1L;

    usz training_count = (usz)training_count_value;
    usz feature_count = (usz)feature_count_value;
    usz neighbor_count = (usz)neighbor_count_value;
    usz feature_start = 3;
    usz label_start = feature_start + training_count * feature_count;
    usz query_start = label_start + training_count;
    usz expected_length = query_start + feature_count;
    if (input_length != expected_length) return -1L;

    for (usz index = feature_start; index < label_start; index++) {
        if (input[index] < -32 || input[index] > 32) return -1L;
    }
    for (usz index = label_start; index < query_start; index++) {
        if (input[index] != 0 && input[index] != 1) return -1L;
    }
    for (usz index = query_start; index < expected_length; index++) {
        if (input[index] < -32 || input[index] > 32) return -1L;
    }

    long query_norm = 0;
    for (usz feature = 0; feature < feature_count; feature++) {
        long coordinate = input[query_start + feature];
        query_norm += coordinate * coordinate;
    }

    long[MAX_TRAINING_COUNT] distances;
    usz[MAX_TRAINING_COUNT] order;
    for (usz row = 0; row < training_count; row++) {
        long row_norm = 0;
        long cross_product = 0;
        for (usz feature = 0; feature < feature_count; feature++) {
            long coordinate = input[feature_start + row * feature_count + feature];
            long query_coordinate = input[query_start + feature];
            row_norm += coordinate * coordinate;
            cross_product += coordinate * query_coordinate;
        }
        distances[row] = query_norm - 2 * cross_product + row_norm;
        order[row] = row;
    }

    for (usz left = 0; left < training_count; left++) {
        for (usz right = left + 1; right < training_count; right++) {
            if (distances[left] == distances[right]) return -1L;
        }
    }

    for (usz index = 1; index < training_count; index++) {
        usz current = order[index];
        usz position = index;
        while (position > 0 && distances[order[position - 1]] > distances[current]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = current;
    }

    usz class_zero_votes = 0;
    usz class_one_votes = 0;
    for (usz index = 0; index < neighbor_count; index++) {
        if (input[label_start + order[index]] == 0) class_zero_votes++;
        else class_one_votes++;
    }
    return class_one_votes > class_zero_votes ? 1L : 0L;
}
