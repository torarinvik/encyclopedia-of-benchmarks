module median_of_running_array_double

import math

const max_count = 64
const max_input_length = 66

fn less_double(left f64, right f64) bool {
	if left < right { return true }
	if left == 0.0 && right == 0.0 {
		return (math.bits_from_f64(left) >> 63) != 0 && (math.bits_from_f64(right) >> 63) == 0
	}
	return false
}
fn push_max(mut heap [64]f64, mut count int, value f64) {
	mut position := count
	count++
	for position > 0 && less_double(heap[(position-1)/2], value) { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_max(mut heap [64]f64, mut count int) f64 {
	result := heap[0]
	count--
	value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2*position+1 < count {
		mut child := 2*position+1
		if child+1 < count && less_double(heap[child], heap[child+1]) { child++ }
		if !less_double(value, heap[child]) { break }
		heap[position] = heap[child]; position = child
	}
	heap[position] = value
	return result
}
fn push_min(mut heap [64]f64, mut count int, value f64) {
	mut position := count
	count++
	for position > 0 && less_double(value, heap[(position-1)/2]) { parent := (position-1)/2; heap[position] = heap[parent]; position = parent }
	heap[position] = value
}
fn pop_min(mut heap [64]f64, mut count int) f64 {
	result := heap[0]
	count--
	value := heap[count]
	if count == 0 { return result }
	mut position := 0
	for 2*position+1 < count {
		mut child := 2*position+1
		if child+1 < count && less_double(heap[child+1], heap[child]) { child++ }
		if !less_double(heap[child], value) { break }
		heap[position] = heap[child]; position = child
	}
	heap[position] = value
	return result
}

@[export: 'median_of_running_array_double']
pub fn median_of_running_array_double(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		count_value := input[0]
		if !count_value.is_finite() || count_value < 1.0 || count_value > f64(max_count) || f64(int(count_value)) != count_value || length != usize(1+int(count_value)) { return -1 }
		count := int(count_value)
		mut lower := [64]f64{}
		mut upper := [64]f64{}
		mut medians := [64]f64{}
		mut lower_count := 0
		mut upper_count := 0
		for i in 0 .. count {
			sample := input[i+1]
			if !sample.is_finite() || sample < -1000000.0 || sample > 1000000.0 { return -1 }
			if upper_count > 0 && less_double(sample, upper[0]) { push_max(mut lower, mut lower_count, sample) }
			else { push_min(mut upper, mut upper_count, sample) }
			if lower_count > upper_count+1 { push_min(mut upper, mut upper_count, pop_max(mut lower, mut lower_count)) }
			else if upper_count > lower_count+1 { push_max(mut lower, mut lower_count, pop_min(mut upper, mut upper_count)) }
			if lower_count > upper_count { medians[i] = lower[0] }
			else if upper_count > lower_count { medians[i] = upper[0] }
			else { medians[i] = (lower[0] + upper[0]) / 2.0 }
		}
		if unsafe { output == nil } || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = medians[i] }
		return i64(count)
	}
}
