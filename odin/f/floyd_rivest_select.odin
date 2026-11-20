package floyd_rivest_select

import "core:c"
import "core:math"

MAX_VALUES :: 64
MAX_INPUT_LENGTH :: c.size_t(MAX_VALUES + 3)
SAMPLE_CUTOFF :: 24

select_kth :: proc(values: [^]i64, initial_left, initial_right, target: int) -> i64 {
	left, right := initial_left, initial_right
	for {
		if right-left > SAMPLE_CUTOFF {
			size := right-left+1
			relative_rank := target-left+1
			size_f, rank_f := f64(size), f64(relative_rank)
			z := math.sqrt_f64(math.ln_f64(size_f))
		sample_size := 0.5 * math.exp_f64(2.0*z/3.0)
			direction := 0.0
			if rank_f < size_f/2.0 { direction = -1.0 }
			else if rank_f > size_f/2.0 { direction = 1.0 }
			spread := 0.5 * math.sqrt_f64(z*sample_size*(size_f-sample_size)/size_f) * direction
			lower_estimate := f64(target)-rank_f*sample_size/size_f+spread
			upper_estimate := f64(target)+(size_f-rank_f)*sample_size/size_f+spread
			sample_left := int(math.floor_f64(lower_estimate))
			if sample_left < left { sample_left = left }
			if sample_left > target { sample_left = target }
			sample_right := int(math.ceil_f64(upper_estimate))
			if sample_right < target { sample_right = target }
			if sample_right > right { sample_right = right }
			_ = select_kth(values, sample_left, sample_right, target)
		}

		pivot := values[target]
		less, scan, greater := left, left, right
		for scan <= greater {
			if values[scan] < pivot {
				values[less], values[scan] = values[scan], values[less]
				less += 1
				scan += 1
			} else if values[scan] > pivot {
				values[scan], values[greater] = values[greater], values[scan]
				greater -= 1
			} else {
				scan += 1
			}
		}
		if target < less { right = less-1 }
		else if target > greater { left = greater+1 }
		else { return pivot }
	}
}

@(export)
floyd_rivest_select :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	count_value, rank_value := input[0], input[1]
	if count_value < 1 || count_value > MAX_VALUES || rank_value < 0 || rank_value >= count_value do return -1
	count := int(count_value)
	if length != c.size_t(count+2) do return -1
	values: [MAX_VALUES]i64
	for index := 0; index < count; index += 1 {
		value := input[index+2]
		if value < 0 || value > 2_147_483_647 do return -1
		for previous := 0; previous < index; previous += 1 {
			if values[previous] == value do return -1
		}
		values[index] = value
	}
	return select_kth(&values[0], 0, count-1, int(rank_value))
}
