module distinct_subarray_aggregates

const max_n = 64
const max_input = 67
const max_segments = 65

fn gcd_nonnegative(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn combine_value(mode i64, a i64, b i64) i64 {
	if mode == 0 { return gcd_nonnegative(a, b) }
	if mode == 1 { return a | b }
	return a & b
}

@[export: 'distinct_subarray_aggregates']
pub fn distinct_subarray_aggregates(input &i64, length usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	unsafe {
		mode, n_value := input[0], input[1]
		if mode < 0 || mode > 2 || n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(2+n) { return -1 }

		mut segment_value := [max_segments]i64{}
		mut segment_left := [max_segments]i64{}
		mut segment_right := [max_segments]i64{}
		mut segment_count := 0
		mut aggregate_sum := i64(0)
		mut suffix_distinct_count := i64(0)
		for right in 0 .. n {
			value := input[2+right]
			if value < 0 || value > 255 { return -1 }
			for j in 0 .. segment_count {
				segment_value[j] = combine_value(mode, segment_value[j], value)
			}
			segment_value[segment_count] = value
			segment_left[segment_count] = i64(right)
			segment_right[segment_count] = i64(right)
			segment_count++

			mut write := 0
			for read in 0 .. segment_count {
				if write > 0 && segment_value[read] == segment_value[write-1] {
					segment_right[write-1] = segment_right[read]
				} else {
					segment_value[write] = segment_value[read]
					segment_left[write] = segment_left[read]
					segment_right[write] = segment_right[read]
					write++
				}
			}
			segment_count = write
			suffix_distinct_count += i64(segment_count)
			for j in 0 .. segment_count {
				aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1)
			}
		}
		return aggregate_sum * 1024 + suffix_distinct_count
	}
}
