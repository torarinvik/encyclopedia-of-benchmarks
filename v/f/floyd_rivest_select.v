module floyd_rivest_select

import math

const max_values = 64
const max_input_length = 67
const sample_threshold = 24

fn select_range(mut values [max_values]i64, left_input int, right_input int, target int) {
	mut left := left_input
	mut right := right_input
	for {
		if right - left > sample_threshold {
			active_count := right - left + 1
			relative_rank := target - left + 1
			active_count_f := f64(active_count)
			relative_rank_f := f64(relative_rank)
			z := math.sqrt(math.log(active_count_f))
			sample_size := 0.5 * math.exp(2.0 * z / 3.0)
			mut direction := 0.0
			if 2 * relative_rank < active_count {
				direction = -1.0
			} else if 2 * relative_rank > active_count {
				direction = 1.0
			}
			spread := 0.5 * math.sqrt(z * sample_size *
				(active_count_f - sample_size) / active_count_f) * direction
			lower_estimate := f64(target) -
				relative_rank_f * sample_size / active_count_f + spread
			upper_estimate := f64(target) +
				(active_count_f - relative_rank_f) * sample_size / active_count_f + spread
			sample_left := int(math.floor(lower_estimate))
			if sample_left < left { sample_left = left }
			if sample_left > target { sample_left = target }
			sample_right := int(math.ceil(upper_estimate))
			if sample_right < target { sample_right = target }
			if sample_right > right { sample_right = right }
			select_range(mut values, sample_left, sample_right, target)
		}

		pivot := values[target]
		mut less := left
		mut scan := left
		mut greater := right
		for scan <= greater {
			if values[scan] < pivot {
				values[less], values[scan] = values[scan], values[less]
				less++
				scan++
			} else if values[scan] > pivot {
				values[scan], values[greater] = values[greater], values[scan]
				greater--
			} else {
				scan++
			}
		}
		if target < less {
			right = less - 1
		} else if target > greater {
			left = greater + 1
		} else {
			return
		}
	}
}

@[export: 'floyd_rivest_select']
pub fn floyd_rivest_select(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		count64, rank64 := input[0], input[1]
		if count64 < 1 || count64 > max_values || rank64 < 0 || rank64 >= count64 { return -1 }
		count := int(count64)
		if length != usize(count + 2) { return -1 }
		mut values := [max_values]i64{}
		for index in 0 .. count {
			value := input[index + 2]
			if value < 0 || value > 2147483647 { return -1 }
			for previous in 0 .. index {
				if values[previous] == value { return -1 }
			}
			values[index] = value
		}
		target := int(rank64)
		select_range(mut values, 0, count - 1, target)
		return values[target]
	}
}
