#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PROFILE_ITEMS 32
#define MAX_INPUT_LENGTH (2 + 4 * MAX_PROFILE_ITEMS)
#define MAX_ITEM_ID 127
#define RATING_SCALE 1000.0
#define MAX_RATING_MILLI INT64_C(1000000000)
#define INVALID_RESULT (-2.0)

static int read_profile(const int64_t *values, size_t start, size_t count,
                        int64_t *ids, double *ratings)
{
    for (size_t index = 0; index < count; ++index) {
        const int64_t item_id = values[start + 2 * index];
        const int64_t rating_milli = values[start + 2 * index + 1];
        if (item_id < 0 || item_id > MAX_ITEM_ID
            || rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI)
            return 0;
        for (size_t earlier = 0; earlier < index; ++earlier)
            if (ids[earlier] == item_id) return 0;
        ids[index] = item_id;
        ratings[index] = (double)rating_milli / RATING_SCALE;
    }
    return 1;
}

double collaborative_filtering_pearson_similarity(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t first_count_value = values[0];
    if (first_count_value < 0 || first_count_value > MAX_PROFILE_ITEMS) return INVALID_RESULT;
    const size_t first_count = (size_t)first_count_value;
    const size_t second_count_position = 1 + 2 * first_count;
    if (second_count_position >= length) return INVALID_RESULT;
    const int64_t second_count_value = values[second_count_position];
    if (second_count_value < 0 || second_count_value > MAX_PROFILE_ITEMS) return INVALID_RESULT;
    const size_t second_count = (size_t)second_count_value;
    if (length != second_count_position + 1 + 2 * second_count) return INVALID_RESULT;

    int64_t first_ids[MAX_PROFILE_ITEMS], second_ids[MAX_PROFILE_ITEMS];
    double first_ratings[MAX_PROFILE_ITEMS], second_ratings[MAX_PROFILE_ITEMS];
    if (!read_profile(values, 1, first_count, first_ids, first_ratings)
        || !read_profile(values, second_count_position + 1, second_count, second_ids, second_ratings))
        return INVALID_RESULT;

    double common_first[MAX_PROFILE_ITEMS], common_second[MAX_PROFILE_ITEMS];
    size_t common_count = 0;
    for (size_t first = 0; first < first_count; ++first) {
        for (size_t second = 0; second < second_count; ++second) {
            if (first_ids[first] == second_ids[second]) {
                common_first[common_count] = first_ratings[first];
                common_second[common_count] = second_ratings[second];
                ++common_count;
                break;
            }
        }
    }
    if (common_count == 0) return 0.0;

    double average_first = 0.0, average_second = 0.0;
    for (size_t index = 0; index < common_count; ++index) {
        average_first += common_first[index];
        average_second += common_second[index];
    }
    average_first /= (double)common_count;
    average_second /= (double)common_count;

    double numerator = 0.0, sum_square_first = 0.0, sum_square_second = 0.0;
    for (size_t index = 0; index < common_count; ++index) {
        const double difference_first = common_first[index] - average_first;
        const double difference_second = common_second[index] - average_second;
        numerator += difference_first * difference_second;
        sum_square_first += difference_first * difference_first;
        sum_square_second += difference_second * difference_second;
    }
    const double denominator = sqrt(sum_square_first * sum_square_second);
    return fabs(denominator) < 1.0e-10 ? 0.0 : numerator / denominator;
}
