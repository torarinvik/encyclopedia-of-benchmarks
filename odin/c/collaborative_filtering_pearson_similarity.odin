package collaborative_filtering_pearson_similarity

import "core:c"
import "core:math"

MAX_PROFILE_ITEMS :: 32
MAX_INPUT_LENGTH :: 2 + 4 * MAX_PROFILE_ITEMS
MAX_RATING_MILLI :: i64(1_000_000_000)
INVALID_RESULT :: f64 = -2.0

@(export)
collaborative_filtering_pearson_similarity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	first_count_value := values[0]
	if first_count_value < 0 || first_count_value > MAX_PROFILE_ITEMS do return INVALID_RESULT
	first_count := usize(first_count_value)
	second_count_position := 1 + 2 * first_count
	if c.size_t(second_count_position) >= length do return INVALID_RESULT
	second_count_value := values[second_count_position]
	if second_count_value < 0 || second_count_value > MAX_PROFILE_ITEMS do return INVALID_RESULT
	second_count := usize(second_count_value)
	if length != c.size_t(second_count_position + 1 + 2 * second_count) do return INVALID_RESULT

	first_ids: [MAX_PROFILE_ITEMS]i64
	second_ids: [MAX_PROFILE_ITEMS]i64
	first_ratings: [MAX_PROFILE_ITEMS]f64
	second_ratings: [MAX_PROFILE_ITEMS]f64
	for index: usize = 0; index < first_count; index += 1 {
		item_id, rating_milli := values[1 + 2 * index], values[2 + 2 * index]
		if item_id < 0 || item_id > 127 || rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI do return INVALID_RESULT
		for earlier: usize = 0; earlier < index; earlier += 1 {
			if first_ids[earlier] == item_id do return INVALID_RESULT
		}
		first_ids[index] = item_id
		first_ratings[index] = f64(rating_milli) / 1000.0
	}
	second_start := second_count_position + 1
	for index: usize = 0; index < second_count; index += 1 {
		item_id, rating_milli := values[second_start + 2 * index], values[second_start + 2 * index + 1]
		if item_id < 0 || item_id > 127 || rating_milli < -MAX_RATING_MILLI || rating_milli > MAX_RATING_MILLI do return INVALID_RESULT
		for earlier: usize = 0; earlier < index; earlier += 1 {
			if second_ids[earlier] == item_id do return INVALID_RESULT
		}
		second_ids[index] = item_id
		second_ratings[index] = f64(rating_milli) / 1000.0
	}

	common_first: [MAX_PROFILE_ITEMS]f64
	common_second: [MAX_PROFILE_ITEMS]f64
	common_count := usize(0)
	for first: usize = 0; first < first_count; first += 1 {
		for second: usize = 0; second < second_count; second += 1 {
			if first_ids[first] == second_ids[second] {
				common_first[common_count] = first_ratings[first]
				common_second[common_count] = second_ratings[second]
				common_count += 1
				break
			}
		}
	}
	if common_count == 0 do return 0.0

	average_first, average_second := f64(0.0), f64(0.0)
	for index: usize = 0; index < common_count; index += 1 {
		average_first += common_first[index]
		average_second += common_second[index]
	}
	average_first /= f64(common_count)
	average_second /= f64(common_count)

	numerator, sum_square_first, sum_square_second := f64(0.0), f64(0.0), f64(0.0)
	for index: usize = 0; index < common_count; index += 1 {
		difference_first := common_first[index] - average_first
		difference_second := common_second[index] - average_second
		numerator += difference_first * difference_second
		sum_square_first += difference_first * difference_first
		sum_square_second += difference_second * difference_second
	}
	denominator := math.sqrt(sum_square_first * sum_square_second)
	if math.abs(denominator) < 1.0e-10 do return 0.0
	return numerator / denominator
}
