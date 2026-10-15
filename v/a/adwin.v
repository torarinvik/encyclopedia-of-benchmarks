module adwin

const max_samples = 256
const max_levels = 16
const max_buckets = 5
const bucket_capacity = max_buckets + 1
const min_subwindow = i64(5)
const input_scale = 1_000_000_000.0

struct Adwin {
mut:
	sizes [max_levels]int
	totals [max_levels][bucket_capacity]f64
	variances [max_levels][bucket_capacity]f64
	width i64
	total f64
	variance f64
	bucket_count int
	delta f64
}

fn adwin_sqrt(value f64) f64 {
	if value <= 0.0 { return 0.0 }
	mut root := if value > 1.0 { value } else { 1.0 }
	for _ in 0 .. 80 { root = 0.5 * (root + value / root) }
	return root
}

fn adwin_ln(input_value f64) f64 {
	mut value := input_value
	mut exponent := 0
	for value >= 2.0 { value *= 0.5; exponent++ }
	ratio := (value - 1.0) / (value + 1.0)
	square := ratio * ratio
	mut term := ratio
	mut sum := 0.0
	for iteration in 0 .. 40 {
		sum += term / f64(2 * iteration + 1)
		term *= square
	}
	return 2.0 * sum + f64(exponent) * 0.693147180559945309417232121458176568
}

fn (mut state Adwin) add_bucket(level int, total f64, variance f64) {
	slot := state.sizes[level]
	state.totals[level][slot] = total
	state.variances[level][slot] = variance
	state.sizes[level]++
}

fn (mut state Adwin) remove_oldest(level int, count int) {
	old_size := state.sizes[level]
	for i in count .. old_size {
		state.totals[level][i - count] = state.totals[level][i]
		state.variances[level][i - count] = state.variances[level][i]
	}
	state.sizes[level] -= count
}

fn (mut state Adwin) compress() {
	for level in 0 .. max_levels - 1 {
		if state.sizes[level] <= max_buckets { break }
		size := f64(1 << level)
		first_mean := state.totals[level][0] / size
		second_mean := state.totals[level][1] / size
		difference := first_mean - second_mean
		merged_variance := state.variances[level][0] + state.variances[level][1] +
			size * size * difference * difference / (size + size)
		merged_total := state.totals[level][0] + state.totals[level][1]
		state.add_bucket(level + 1, merged_total, merged_variance)
		state.remove_oldest(level, 2)
		state.bucket_count--
	}
}

fn (mut state Adwin) insert(value f64) {
	state.width++
	state.add_bucket(0, value, 0.0)
	state.bucket_count++
	if state.width > 1 {
		deviation := value - state.total / f64(state.width - 1)
		state.variance += f64(state.width - 1) * deviation * deviation / f64(state.width)
	}
	state.total += value
	state.compress()
}

fn (state Adwin) significant(old_width i64, recent_width i64, difference f64) bool {
	harmonic := 1.0 / f64(old_width - min_subwindow + 1) + 1.0 / f64(recent_width - min_subwindow + 1)
	confidence := adwin_ln(2.0 * adwin_ln(f64(state.width)) / state.delta)
	window_variance := state.variance / f64(state.width)
	epsilon := adwin_sqrt(2.0 * harmonic * window_variance * confidence) + 2.0 / 3.0 * confidence * harmonic
	mut absolute_difference := difference
	if absolute_difference < 0.0 { absolute_difference = -absolute_difference }
	return absolute_difference > epsilon
}

fn (mut state Adwin) drop_oldest() {
	mut level := max_levels - 1
	for level > 0 && state.sizes[level] == 0 { level-- }
	size := i64(1 << level)
	bucket_total := state.totals[level][0]
	state.width -= size
	state.total -= bucket_total
	if state.width > 0 {
		bucket_mean := bucket_total / f64(size)
		difference := bucket_mean - state.total / f64(state.width)
		state.variance -= state.variances[level][0] + f64(size) * f64(state.width) * difference * difference / f64(size + state.width)
	} else {
		state.variance = 0.0
	}
	if state.variance < 0.0 { state.variance = 0.0 }
	state.remove_oldest(level, 1)
	state.bucket_count--
}

fn (mut state Adwin) detect_change() bool {
	mut changed := false
	mut searching := true
	for searching && state.width >= 2 * min_subwindow {
		searching = false
		mut stop := false
		mut old_width := i64(0)
		mut old_total := 0.0
		for level := max_levels - 1; level >= 0 && !stop; level-- {
			for bucket in 0 .. state.sizes[level] {
				if level == 0 && bucket == state.sizes[level] - 1 { stop = true; break }
				old_width += i64(1 << level)
				old_total += state.totals[level][bucket]
				recent_width := state.width - old_width
				recent_total := state.total - old_total
				if recent_width < min_subwindow { stop = true; break }
				if old_width >= min_subwindow && state.significant(old_width, recent_width,
					old_total / f64(old_width) - recent_total / f64(recent_width)) {
					changed = true
					searching = true
					state.drop_oldest()
					stop = true
					break
				}
			}
		}
	}
	return changed
}

@[export: 'adwin']
pub fn adwin(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 3 || length > 2 + max_samples { return -1 }
	unsafe {
		sample_count_value := input[0]
		delta_value := input[1]
		if sample_count_value < 1 || sample_count_value > max_samples ||
			length != usize(2 + sample_count_value) || delta_value < 1 || delta_value > 100000000 { return -1 }
		sample_count := int(sample_count_value)
		for i in 0 .. sample_count {
			if input[2 + i] < -1000000000 || input[2 + i] > 1000000000 { return -1 }
		}
		if output_capacity < 16 * sample_count { return -2 }
		mut state := Adwin{delta: f64(delta_value) / input_scale}
		for i in 0 .. sample_count {
			state.insert(f64(input[2 + i]) / input_scale)
			flag := if state.detect_change() { i64(1) } else { i64(0) }
			for word, value in [flag, state.width] {
				for byte in 0 .. 8 { output[16 * i + 8 * word + byte] = u8((value >> (8 * byte)) & 255) }
			}
		}
		return i64(2 * sample_count)
	}
}
