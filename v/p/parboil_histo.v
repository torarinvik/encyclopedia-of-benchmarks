module parboil_histo

const max_bins = 256
const max_samples = 1024

@[export: 'parboil_histo']
pub fn parboil_histo(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 3 || input_length > 3 + max_samples { return -1 }
	mut values := [3 + max_samples]i64{}
	unsafe { for i in 0 .. int(input_length) { values[i] = input[i] } }
	iterations, bins, samples := values[0], values[1], values[2]
	if iterations < 0 || iterations > 8 || bins < 1 || bins > max_bins || samples < 0 || samples > max_samples || input_length != usize(3 + samples) { return -1 }
	for i in 0 .. int(samples) { if values[3+i] < 0 || values[3+i] >= bins { return -1 } }
	if unsafe { output == nil } || output_capacity < usize(bins) { return -2 }
	mut histogram := [max_bins]u8{}
	for _ in 0 .. int(iterations) {
		for i in 0 .. int(bins) { histogram[i] = 0 }
		for i in 0 .. int(samples) {
			bin := int(values[3+i])
			if histogram[bin] < 255 { histogram[bin]++ }
		}
	}
	unsafe { for i in 0 .. int(bins) { output[i] = histogram[i] } }
	return bins
}
