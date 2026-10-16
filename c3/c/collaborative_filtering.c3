module collaborative_filtering;

extern fn double fabs(double value);

const usz MAX_USERS = 65;
const usz MAX_INPUT_LENGTH = 1 + 4 * MAX_USERS;
const long MAX_TICKS = 1000000000000L;
const long MAX_RATING_MILLI = 1000000000L;
const double INVALID_RESULT = -1.0e300;

fn double collaborative_filtering(long* values, usz length) @export("collaborative_filtering") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_USERS) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != 1 + 4 * count) return INVALID_RESULT;

    double total_similarity = 0.0;
    double weighted_sum = 0.0;
    usz target_user_count = 0;
    for (usz index = 0; index < count; index++) {
        usz offset = 1 + 4 * index;
        long is_target_user = values[offset];
        long has_target_rating = values[offset + 1];
        long similarity_ticks = values[offset + 2];
        long rating_milli = values[offset + 3];
        if ((is_target_user != 0 && is_target_user != 1)
            || (has_target_rating != 0 && has_target_rating != 1)
            || similarity_ticks < -MAX_TICKS || similarity_ticks > MAX_TICKS
            || rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI)
            return INVALID_RESULT;
        if (is_target_user == 1) {
            target_user_count++;
            continue;
        }
        if (has_target_rating == 0) continue;
        double similarity = (double)similarity_ticks / 1000000000000.0;
        double rating = (double)rating_milli / 1000.0;
        total_similarity += fabs(similarity);
        weighted_sum += similarity * rating;
    }
    if (target_user_count != 1) return INVALID_RESULT;
    return fabs(total_similarity) < 1.0e-10 ? 0.0 : weighted_sum / total_similarity;
}
