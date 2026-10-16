module collaborative_filtering_pearson_similarity

import math

const max_profile_items = 32
const max_input_length = 2 + 4 * max_profile_items
const max_rating_milli = i64(1_000_000_000)
const invalid_result = -2.0

@[export: 'collaborative_filtering_pearson_similarity']
pub fn collaborative_filtering_pearson_similarity(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return invalid_result }
	unsafe {
		first_count_value := values[0]
		if first_count_value < 0 || first_count_value > max_profile_items { return invalid_result }
		first_count := int(first_count_value)
		second_count_position := 1 + 2 * first_count
		if usize(second_count_position) >= length { return invalid_result }
		second_count_value := values[second_count_position]
		if second_count_value < 0 || second_count_value > max_profile_items { return invalid_result }
		second_count := int(second_count_value)
		if length != usize(second_count_position + 1 + 2 * second_count) { return invalid_result }

		mut first_ids := [max_profile_items]i64{}
		mut second_ids := [max_profile_items]i64{}
		mut first_ratings := [max_profile_items]f64{}
		mut second_ratings := [max_profile_items]f64{}
		for index in 0 .. first_count {
			item_id, rating_milli := values[1 + 2 * index], values[2 + 2 * index]
			if item_id < 0 || item_id > 127 || rating_milli < -max_rating_milli || rating_milli > max_rating_milli { return invalid_result }
			for earlier in 0 .. index { if first_ids[earlier] == item_id { return invalid_result } }
			first_ids[index] = item_id
			first_ratings[index] = f64(rating_milli) / 1000.0
		}
		second_start := second_count_position + 1
		for index in 0 .. second_count {
			item_id, rating_milli := values[second_start + 2 * index], values[second_start + 2 * index + 1]
			if item_id < 0 || item_id > 127 || rating_milli < -max_rating_milli || rating_milli > max_rating_milli { return invalid_result }
			for earlier in 0 .. index { if second_ids[earlier] == item_id { return invalid_result } }
			second_ids[index] = item_id
			second_ratings[index] = f64(rating_milli) / 1000.0
		}

		mut common_first := [max_profile_items]f64{}
		mut common_second := [max_profile_items]f64{}
		mut common_count := 0
		for first in 0 .. first_count {
			for second in 0 .. second_count {
				if first_ids[first] == second_ids[second] {
					common_first[common_count] = first_ratings[first]
					common_second[common_count] = second_ratings[second]
					common_count++
					break
				}
			}
		}
		if common_count == 0 { return 0.0 }

		mut average_first := 0.0
		mut average_second := 0.0
		for index in 0 .. common_count {
			average_first += common_first[index]
			average_second += common_second[index]
		}
		average_first /= f64(common_count)
		average_second /= f64(common_count)

		mut numerator := 0.0
		mut sum_square_first := 0.0
		mut sum_square_second := 0.0
		for index in 0 .. common_count {
			difference_first := common_first[index] - average_first
			difference_second := common_second[index] - average_second
			numerator += difference_first * difference_second
			sum_square_first += difference_first * difference_first
			sum_square_second += difference_second * difference_second
		}
		denominator := math.sqrt(sum_square_first * sum_square_second)
		if math.abs(denominator) < 1.0e-10 { return 0.0 }
		return numerator / denominator
	}
}
