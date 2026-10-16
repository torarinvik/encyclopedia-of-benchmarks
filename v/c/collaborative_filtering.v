module collaborative_filtering

import math

const max_users = 65
const max_input_length = 1 + 4 * max_users
const max_similarity_ticks = i64(1_000_000_000_000)
const max_rating_milli = i64(1_000_000_000)
const invalid_result = -1.0e300

@[export: 'collaborative_filtering']
pub fn collaborative_filtering(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 1 || length > max_input_length { return invalid_result }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_users { return invalid_result }
		count := int(count_value)
		if length != usize(1 + 4 * count) { return invalid_result }

		mut total_similarity := 0.0
		mut weighted_sum := 0.0
		mut target_user_count := 0
		for index in 0 .. count {
			offset := 1 + 4 * index
			is_target_user, has_target_rating, similarity_ticks, rating_milli := values[offset], values[offset + 1], values[offset + 2], values[offset + 3]
			if (is_target_user != 0 && is_target_user != 1) || (has_target_rating != 0 && has_target_rating != 1) ||
				similarity_ticks < -max_similarity_ticks || similarity_ticks > max_similarity_ticks ||
				rating_milli < -max_rating_milli || rating_milli > max_rating_milli { return invalid_result }
			if is_target_user == 1 {
				target_user_count += 1
				continue
			}
			if has_target_rating == 0 { continue }
			similarity := f64(similarity_ticks) / 1_000_000_000_000.0
			rating := f64(rating_milli) / 1000.0
			total_similarity += math.abs(similarity)
			weighted_sum += similarity * rating
		}
		if target_user_count != 1 { return invalid_result }
		if math.abs(total_similarity) < 1.0e-10 { return 0.0 }
		return weighted_sum / total_similarity
	}
}
