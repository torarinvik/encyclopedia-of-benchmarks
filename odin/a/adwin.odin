package adwin

import "core:c"

MAX_SAMPLES :: 256
MAX_LEVELS :: 16
MAX_BUCKETS :: 5
BUCKET_CAPACITY :: MAX_BUCKETS + 1
MIN_SUBWINDOW :: 5
INPUT_SCALE :: 1_000_000_000.0

Adwin :: struct {
	sizes: [MAX_LEVELS]int,
	totals: [MAX_LEVELS][BUCKET_CAPACITY]f64,
	variances: [MAX_LEVELS][BUCKET_CAPACITY]f64,
	width: i64,
	total: f64,
	variance: f64,
	bucket_count: int,
	delta: f64,
}

adwin_sqrt :: proc "contextless" (value: f64) -> f64 {
	if value <= 0.0 do return 0.0
	root := value
	if root < 1.0 do root = 1.0
	for iteration := 0; iteration < 80; iteration += 1 { root = 0.5 * (root + value / root) }
	return root
}

adwin_ln :: proc "contextless" (input_value: f64) -> f64 {
	value := input_value
	exponent := 0
	for value >= 2.0 { value *= 0.5; exponent += 1 }
	ratio := (value - 1.0) / (value + 1.0)
	square := ratio * ratio
	term, sum := ratio, 0.0
	for iteration := 0; iteration < 40; iteration += 1 {
		sum += term / f64(2 * iteration + 1)
		term *= square
	}
	return 2.0 * sum + f64(exponent) * 0.693147180559945309417232121458176568
}

add_bucket :: proc "contextless" (state: ^Adwin, level: int, total: f64, variance: f64) {
	slot := state.sizes[level]
	state.totals[level][slot] = total
	state.variances[level][slot] = variance
	state.sizes[level] += 1
}

remove_oldest :: proc "contextless" (state: ^Adwin, level: int, count: int) {
	old_size := state.sizes[level]
	for i := count; i < old_size; i += 1 {
		state.totals[level][i-count] = state.totals[level][i]
		state.variances[level][i-count] = state.variances[level][i]
	}
	state.sizes[level] -= count
}

compress :: proc "contextless" (state: ^Adwin) {
	for level := 0; level + 1 < MAX_LEVELS; level += 1 {
		if state.sizes[level] <= MAX_BUCKETS do break
		size := f64(u32(1) << u32(level))
		first_mean := state.totals[level][0] / size
		second_mean := state.totals[level][1] / size
		difference := first_mean - second_mean
		merged_variance := state.variances[level][0] + state.variances[level][1] +
			size * size * difference * difference / (size + size)
		merged_total := state.totals[level][0] + state.totals[level][1]
		add_bucket(state, level+1, merged_total, merged_variance)
		remove_oldest(state, level, 2)
		state.bucket_count -= 1
	}
}

insert :: proc "contextless" (state: ^Adwin, value: f64) {
	state.width += 1
	add_bucket(state, 0, value, 0.0)
	state.bucket_count += 1
	if state.width > 1 {
		deviation := value - state.total / f64(state.width-1)
		state.variance += f64(state.width-1) * deviation * deviation / f64(state.width)
	}
	state.total += value
	compress(state)
}

significant :: proc "contextless" (state: ^Adwin, old_width: i64, recent_width: i64, difference: f64) -> bool {
	harmonic := 1.0 / f64(old_width-MIN_SUBWINDOW+1) + 1.0 / f64(recent_width-MIN_SUBWINDOW+1)
	confidence := adwin_ln(2.0 * adwin_ln(f64(state.width)) / state.delta)
	window_variance := state.variance / f64(state.width)
	epsilon := adwin_sqrt(2.0 * harmonic * window_variance * confidence) + 2.0 / 3.0 * confidence * harmonic
	absolute_difference := difference
	if absolute_difference < 0.0 do absolute_difference = -absolute_difference
	return absolute_difference > epsilon
}

drop_oldest :: proc "contextless" (state: ^Adwin) {
	level := MAX_LEVELS - 1
	for level > 0 && state.sizes[level] == 0 { level -= 1 }
	size := i64(u32(1) << u32(level))
	bucket_total := state.totals[level][0]
	state.width -= size
	state.total -= bucket_total
	if state.width > 0 {
		bucket_mean := bucket_total / f64(size)
		difference := bucket_mean - state.total / f64(state.width)
		state.variance -= state.variances[level][0] + f64(size) * f64(state.width) * difference * difference / f64(size+state.width)
	} else {
		state.variance = 0.0
	}
	if state.variance < 0.0 do state.variance = 0.0
	remove_oldest(state, level, 1)
	state.bucket_count -= 1
}

detect_change :: proc "contextless" (state: ^Adwin) -> bool {
	changed, searching := false, true
	for searching && state.width >= 2 * MIN_SUBWINDOW {
		searching = false
		stop := false
		old_width: i64 = 0
		old_total := 0.0
		for level := MAX_LEVELS - 1; level >= 0 && !stop; level -= 1 {
			for bucket := 0; bucket < state.sizes[level]; bucket += 1 {
				if level == 0 && bucket == state.sizes[level]-1 { stop = true; break }
			old_width += i64(u32(1) << u32(level))
				old_total += state.totals[level][bucket]
				recent_width := state.width - old_width
				recent_total := state.total - old_total
				if recent_width < MIN_SUBWINDOW { stop = true; break }
				if old_width >= MIN_SUBWINDOW && significant(state, old_width, recent_width,
					old_total / f64(old_width) - recent_total / f64(recent_width)) {
					changed = true
					searching = true
					drop_oldest(state)
					stop = true
					break
				}
			}
		}
	}
	return changed
}

write_i64 :: proc "contextless" (output: [^]u8, word_index: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[8*word_index+byte] = u8((bits >> u64(8*byte)) & 255)
	}
}

@(export)
adwin :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(2+MAX_SAMPLES) do return -1
	sample_count_value, delta_value := input[0], input[1]
	invalid_header := sample_count_value < 1 || sample_count_value > MAX_SAMPLES ||
		length != c.size_t(2+int(sample_count_value)) || delta_value < 1 || delta_value > 100_000_000
	if invalid_header do return -1
	sample_count := int(sample_count_value)
	for i := 0; i < sample_count; i += 1 {
		if input[2+i] < -1_000_000_000 || input[2+i] > 1_000_000_000 do return -1
	}
	if output == nil || output_capacity < c.size_t(16*sample_count) do return -2
	state := Adwin{delta = f64(delta_value) / INPUT_SCALE}
	for i := 0; i < sample_count; i += 1 {
		insert(&state, f64(input[2+i]) / INPUT_SCALE)
		flag: i64 = 0
		if detect_change(&state) do flag = 1
		write_i64(output, 2*i, flag)
		write_i64(output, 2*i+1, state.width)
	}
	return i64(2*sample_count)
}
