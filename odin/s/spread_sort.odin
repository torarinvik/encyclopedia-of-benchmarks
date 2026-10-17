package spread_sort

import "core:c"

MAX_LENGTH :: 128
INSERTION_THRESHOLD :: 16
MAX_BUCKETS :: 8
BUCKET_STRIDE :: 128

spread_sort_segment :: proc(values: [^]i32, length: int) {
	if length < 2 do return
	if length <= INSERTION_THRESHOLD {
		for index := 1; index < length; index += 1 {
			key := values[index]
			position := index
			for position > 0 && values[position - 1] > key {
				values[position] = values[position - 1]
				position -= 1
			}
			values[position] = key
		}
		return
	}

	minimum := values[0]
	maximum := values[0]
	for index := 1; index < length; index += 1 {
		if values[index] < minimum do minimum = values[index]
		if values[index] > maximum do maximum = values[index]
	}
	if minimum == maximum do return

	bucket_count := length / INSERTION_THRESHOLD
	if bucket_count < 2 do bucket_count = 2
	middle_bucket := bucket_count / 2
	bucket_values: [1024]i32
	bucket_sizes: [MAX_BUCKETS]int
	for index := 0; index < MAX_BUCKETS; index += 1 {
		bucket_sizes[index] = 0
	}
	for index := 0; index < length; index += 1 {
		bucket := 0
		if values[index] != minimum do bucket = middle_bucket
		position := bucket * BUCKET_STRIDE + bucket_sizes[bucket]
		bucket_values[position] = values[index]
		bucket_sizes[bucket] += 1
	}

	written := 0
	for bucket := 0; bucket < bucket_count; bucket += 1 {
		if bucket_sizes[bucket] > 0 {
			spread_sort_segment(&bucket_values[bucket * BUCKET_STRIDE], bucket_sizes[bucket])
			for index := 0; index < bucket_sizes[bucket]; index += 1 {
				values[written] = bucket_values[bucket * BUCKET_STRIDE + index]
				written += 1
			}
		}
	}
}

@(export, link_name="spread_sort")
spread_sort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length > c.size_t(MAX_LENGTH) do return -1
	values: [MAX_LENGTH]i32
	for index := 0; index < int(length); index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	if length == 0 do return 0

	output_bytes := length * 4
	if output == nil || capacity < output_bytes do return -2
	spread_sort_segment(&values[0], int(length))
	for index := 0; index < int(length); index += 1 {
		bits := transmute(u32)(values[index])
		output[index * 4] = u8(bits & 255)
		output[index * 4 + 1] = u8((bits >> 8) & 255)
		output[index * 4 + 2] = u8((bits >> 16) & 255)
		output[index * 4 + 3] = u8((bits >> 24) & 255)
	}
	return i64(output_bytes)
}
