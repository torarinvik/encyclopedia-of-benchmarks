package collaborative_filtering

import "core:c"
import "core:math"

MAX_USERS :: 65
MAX_INPUT_LENGTH :: 1 + 4 * MAX_USERS
MAX_SIMILARITY_TICKS :: i64(1_000_000_000_000)
MAX_RATING_MILLI :: i64(1_000_000_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
collaborative_filtering :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	count_value := values[0]
	if count_value < 1 || count_value > MAX_USERS do return INVALID_RESULT
	count := usize(count_value)
	if length != c.size_t(1 + 4 * count) do return INVALID_RESULT

	total_similarity := f64(0.0)
	weighted_sum := f64(0.0)
	target_user_count := 0
	for index: usize = 0; index < count; index += 1 {
		offset := 1 + 4 * index
		is_target_user, has_target_rating, similarity_ticks, rating_milli := values[offset], values[offset + 1], values[offset + 2], values[offset + 3]
		if (is_target_user != 0 && is_target_user != 1) || (has_target_rating != 0 && has_target_rating != 1) ||
			similarity_ticks < -MAX_SIMILARITY_TICKS || similarity_ticks > MAX_SIMILARITY_TICKS ||
			rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI do return INVALID_RESULT
		if is_target_user == 1 {
			target_user_count += 1
			continue
		}
		if has_target_rating == 0 do continue
		similarity := f64(similarity_ticks) / 1_000_000_000_000.0
		rating := f64(rating_milli) / 1000.0
		total_similarity += math.abs(similarity)
		weighted_sum += similarity * rating
	}
	if target_user_count != 1 do return INVALID_RESULT
	if math.abs(total_similarity) < 1.0e-10 do return 0.0
	return weighted_sum / total_similarity
}
