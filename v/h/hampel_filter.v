module hampel_filter

import math

fn insert_sorted(mut values [3]f64, size int, value f64) int {
	mut position := 0
	for position < size && values[position] < value { position++ }
	for index := size; index > position; index-- { values[index] = values[index - 1] }
	values[position] = value
	return size + 1
}

fn median(values [3]f64, size int) f64 {
	unsafe {
		middle := size / 2
		if size % 2 == 1 { return values[middle] }
		return 0.5 * (values[middle - 1] + values[middle])
	}
}

fn mad(values [3]f64, size int, center f64) f64 {
	unsafe {
		mut deviations := [3]f64{}
		mut deviation_count := 0
		for index in 0 .. size {
			deviation := math.abs(values[index] - center)
			deviation_count = insert_sorted(mut deviations, deviation_count, deviation)
		}
		return median(deviations, deviation_count)
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'hampel_filter']
pub fn hampel_filter(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 { return -1 }
		count_value := input[0]
		if count_value < 0 || count_value > 128 || length != usize(count_value) + 1 { return -1 }
		count := int(count_value)
		for index in 0 .. count {
			if input[index + 1] < -1000 || input[index + 1] > 1000 { return -1 }
		}
		if capacity < usize(count * 8) || (count > 0 && output == nil) { return -2 }

		mut arrival := [3]f64{}
		mut sorted := [3]f64{}
		mut size := 0
		mut oldest := 0
		for index in 0 .. count {
			value := f64(input[index + 1])
			if size == 3 {
				mut position := 0
				for position < size && sorted[position] != arrival[oldest] { position++ }
				if position < size {
					for cursor := position + 1; cursor < size; cursor++ { sorted[cursor - 1] = sorted[cursor] }
					size--
				}
			}
			size = insert_sorted(mut sorted, size, value)
			arrival[oldest] = value
			oldest = (oldest + 1) % 3

			center := median(sorted, size)
			deviation := mad(sorted, size, center)
			filtered := value
			if math.abs(value - center) > 3.0 * 1.4826 * deviation { filtered = center }
			put_i64_le(mut output, index * 8, i64(filtered))
		}
		return i64(count * 8)
	}
}
