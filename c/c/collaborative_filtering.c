#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_USERS 65
#define MAX_INPUT_LENGTH (1 + 4 * MAX_USERS)
#define SIMILARITY_SCALE 1000000000000.0
#define RATING_SCALE 1000.0
#define MAX_SIMILARITY_TICKS INT64_C(1000000000000)
#define MAX_RATING_MILLI INT64_C(1000000000)
#define INVALID_RESULT (-1.0e300)

double collaborative_filtering(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_USERS) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 1 + 4 * count) return INVALID_RESULT;

    double total_similarity = 0.0;
    double weighted_sum = 0.0;
    size_t target_user_count = 0;
    for (size_t index = 0; index < count; ++index) {
        const size_t offset = 1 + 4 * index;
        const int64_t is_target_user = values[offset];
        const int64_t has_target_rating = values[offset + 1];
        const int64_t similarity_ticks = values[offset + 2];
        const int64_t rating_milli = values[offset + 3];
        if ((is_target_user != 0 && is_target_user != 1)
            || (has_target_rating != 0 && has_target_rating != 1)
            || similarity_ticks < -MAX_SIMILARITY_TICKS || similarity_ticks > MAX_SIMILARITY_TICKS
            || rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI)
            return INVALID_RESULT;
        if (is_target_user == 1) {
            ++target_user_count;
            continue;
        }
        if (has_target_rating == 0) continue;
        const double similarity = (double)similarity_ticks / SIMILARITY_SCALE;
        const double rating = (double)rating_milli / RATING_SCALE;
        total_similarity += fabs(similarity);
        weighted_sum += similarity * rating;
    }
    if (target_user_count != 1) return INVALID_RESULT;
    return fabs(total_similarity) < 1.0e-10 ? 0.0 : weighted_sum / total_similarity;
}
