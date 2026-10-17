module spread_sort

const (
	max_length = 128
	insertion_threshold = 16
)

fn spread_sort_segment(mut values []i32) {
	if values.len < 2 {
		return
	}
	if values.len <= insertion_threshold {
		for index in 1 .. values.len {
			key := values[index]
			mut position := index
			for position > 0 && values[position - 1] > key {
				values[position] = values[position - 1]
				position--
			}
			values[position] = key
		}
		return
	}

	mut minimum := values[0]
	mut maximum := values[0]
	for index in 1 .. values.len {
		if values[index] < minimum {
			minimum = values[index]
		}
		if values[index] > maximum {
			maximum = values[index]
		}
	}
	if minimum == maximum {
		return
	}

	bucket_count := max((values.len / insertion_threshold), 2)
	middle_bucket := bucket_count / 2
	mut buckets := [][]i32{len: bucket_count}
	for value in values {
		if value == minimum {
			buckets[0] << value
		} else {
			buckets[middle_bucket] << value
		}
	}

	mut written := 0
	for bucket := 0; bucket < bucket_count; bucket++ {
		if buckets[bucket].len == 0 {
			continue
		}
		spread_sort_segment(mut buckets[bucket])
		for value in buckets[bucket] {
			values[written] = value
			written++
		}
	}
}

@[export: 'spread_sort']
pub fn spread_sort(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length > max_length {
		return -1
	}
	mut values := []i32{len: int(length)}
	for index in 0 .. int(length) {
		value := unsafe { input[index] }
		if value < i64(min_i32) || value > i64(max_i32) {
			return -1
		}
		values[index] = i32(value)
	}
	if length == 0 {
		return 0
	}

	output_bytes := length * 4
	if output == nil || capacity < output_bytes {
		return -2
	}
	spread_sort_segment(mut values)
	for index, value in values {
		bits := u32(value)
		unsafe {
			output[index * 4] = u8(bits & 255)
			output[index * 4 + 1] = u8((bits >> 8) & 255)
			output[index * 4 + 2] = u8((bits >> 16) & 255)
			output[index * 4 + 3] = u8((bits >> 24) & 255)
		}
	}
	return i64(output_bytes)
}

const (
	min_i32 = -2147483648
	max_i32 = 2147483647
)
