module median_filter

const max_window = 16
const max_samples = 64

fn lower_bound(sorted &f64, size int, value f64) int {
	unsafe {
		mut low := 0
		mut high := size
		for low < high {
			middle := low + (high - low) / 2
			if sorted[middle] < value { low = middle + 1 } else { high = middle }
		}
		return low
	}
}

@[export: 'median_filter']
pub fn median_filter(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		window_value := input[0]
		count_value := input[1]
		if window_value != window_value || window_value < 1.0 || window_value > 16.0 || window_value != f64(i64(window_value)) { return -1 }
		if count_value != count_value || count_value < 0.0 || count_value > 64.0 || count_value != f64(i64(count_value)) { return -1 }
		window := int(window_value)
		count := int(count_value)
		if int(length) != 2 + count { return -1 }
		mut samples := [max_samples]f64{}
		for index in 0 .. count {
			value := input[2 + index]
			if value != value || value < -1000000.0 || value > 1000000.0 { return -1 }
			samples[index] = value
		}
		if output == nil || output_capacity < usize(count) { return -2 }

		mut arrival := [max_window]f64{}
		mut sorted := [max_window]f64{}
		mut result := [max_samples]f64{}
		mut size := 0
		mut oldest := 0
		for index in 0 .. count {
			value := samples[index]
			if size == window {
				position := lower_bound(&sorted[0], size, arrival[oldest])
				for shift := position + 1; shift < size; shift++ { sorted[shift - 1] = sorted[shift] }
				size--
			}
			position := lower_bound(&sorted[0], size, value)
			mut shift := size
			for shift > position { sorted[shift] = sorted[shift - 1]; shift-- }
			sorted[position] = value
			arrival[oldest] = value
			oldest = (oldest + 1) % window
			size++
			middle := size / 2
			if size % 2 != 0 { result[index] = sorted[middle] }
			else { result[index] = 0.5 * (sorted[middle - 1] + sorted[middle]) }
		}
		for index in 0 .. count { output[index] = result[index] }
		return i64(count)
	}
}
