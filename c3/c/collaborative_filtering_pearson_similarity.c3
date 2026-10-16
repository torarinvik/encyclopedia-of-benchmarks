module collaborative_filtering_pearson_similarity;

extern fn double fabs(double value);
extern fn double sqrt(double value);

const usz MAX_PROFILE_ITEMS = 32;
const usz MAX_INPUT_LENGTH = 2 + 4 * MAX_PROFILE_ITEMS;
const long MAX_RATING_MILLI = 1000000000L;
const double INVALID_RESULT = -2.0;

fn bool read_profile(long* values, usz start, usz count,
                     long* ids, double* ratings) {
    for (usz index = 0; index < count; index++) {
        long item_id = values[start + 2 * index];
        long rating_milli = values[start + 2 * index + 1];
        if (item_id < 0 || item_id > 127 || rating_milli < -MAX_RATING_MILLI
            || rating_milli > MAX_RATING_MILLI) return false;
        for (usz earlier = 0; earlier < index; earlier++)
            if (ids[earlier] == item_id) return false;
        ids[index] = item_id;
        ratings[index] = (double)rating_milli / 1000.0;
    }
    return true;
}

fn double collaborative_filtering_pearson_similarity(long* values, usz length)
    @export("collaborative_filtering_pearson_similarity") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long first_count_value = values[0];
    if (first_count_value < 0 || first_count_value > (long)MAX_PROFILE_ITEMS) return INVALID_RESULT;
    usz first_count = (usz)first_count_value;
    usz second_count_position = 1 + 2 * first_count;
    if (second_count_position >= length) return INVALID_RESULT;
    long second_count_value = values[second_count_position];
    if (second_count_value < 0 || second_count_value > (long)MAX_PROFILE_ITEMS) return INVALID_RESULT;
    usz second_count = (usz)second_count_value;
    if (length != second_count_position + 1 + 2 * second_count) return INVALID_RESULT;

    long[MAX_PROFILE_ITEMS] first_ids, second_ids;
    double[MAX_PROFILE_ITEMS] first_ratings, second_ratings;
    if (!read_profile(values, 1, first_count, &first_ids[0], &first_ratings[0])
        || !read_profile(values, second_count_position + 1, second_count,
                         &second_ids[0], &second_ratings[0])) return INVALID_RESULT;

    double[MAX_PROFILE_ITEMS] common_first, common_second;
    usz common_count = 0;
    for (usz first = 0; first < first_count; first++) {
        for (usz second = 0; second < second_count; second++) {
            if (first_ids[first] == second_ids[second]) {
                common_first[common_count] = first_ratings[first];
                common_second[common_count] = second_ratings[second];
                common_count++;
                break;
            }
        }
    }
    if (common_count == 0) return 0.0;

    double average_first = 0.0, average_second = 0.0;
    for (usz index = 0; index < common_count; index++) {
        average_first += common_first[index];
        average_second += common_second[index];
    }
    average_first /= (double)common_count;
    average_second /= (double)common_count;

    double numerator = 0.0, sum_square_first = 0.0, sum_square_second = 0.0;
    for (usz index = 0; index < common_count; index++) {
        double difference_first = common_first[index] - average_first;
        double difference_second = common_second[index] - average_second;
        numerator += difference_first * difference_second;
        sum_square_first += difference_first * difference_first;
        sum_square_second += difference_second * difference_second;
    }
    double denominator = sqrt(sum_square_first * sum_square_second);
    return fabs(denominator) < 1.0e-10 ? 0.0 : numerator / denominator;
}
