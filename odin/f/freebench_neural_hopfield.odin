package freebench_neural_hopfield

import "core:c"
import "core:math"

PATTERN_COUNT :: 10
MAX_NEURONS :: 8

activation :: proc(value: f32) -> f32 {
	x := f64(value)
	if x > 200.0 do x = 200.0
	if x < -200.0 do x = -200.0
	e := math.exp_f64(-x)
	return f32((1.0 - e) / (1.0 + e))
}

run_cont :: proc(weights: []f32, source: []i64, neurons: int, dest: []i64) -> bool {
	temp_a: [MAX_NEURONS]f32
	temp_c: [MAX_NEURONS]i64
	for neuron in 0..<neurons {
		dest[neuron] = source[neuron]
		temp_a[neuron] = f32(source[neuron])
	}
	stable, threshold := false, false
	iterations := 0
	for !stable && iterations < 500 {
		threshold_iterations := 0
		for row in 0..<neurons {
			sum: f32 = 0
			for neuron in 0..<neurons { sum += weights[row*neurons+neuron]*f32(source[neuron]) }
			temp_a[row] = activation(sum)
		}
		for !threshold && threshold_iterations < 50 {
			threshold = true
			for row in 0..<neurons {
				magnitude := temp_a[row]
				if magnitude < 0 { magnitude = -magnitude }
				if magnitude < 0.7 {
					sum: f32 = 0
					for neuron in 0..<neurons { sum += weights[row*neurons+neuron]*temp_a[neuron] }
					temp_a[row] = activation(sum)
					if temp_a[row] < 0.7 { threshold = false }
				}
			}
			threshold_iterations += 1
		}
		same := true
		for neuron in 0..<neurons {
			temp_c[neuron] = -1
			if temp_a[neuron] > 0 { temp_c[neuron] = 1 }
			if dest[neuron] != temp_c[neuron] { same = false }
		}
		if same { stable = true } else {
			for neuron in 0..<neurons {
				if dest[neuron] != temp_c[neuron] { dest[neuron] = temp_c[neuron]; break }
			}
			for neuron in 0..<neurons { temp_a[neuron] = f32(dest[neuron]) }
		}
		iterations += 1
	}
	return iterations < 500
}

@(export)
freebench_neural_hopfield :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 94 do return -1
	width, height, pattern_count := input[0], input[1], input[2]
	if width < 1 || width > 8 || height < 1 || height > 8 || pattern_count != PATTERN_COUNT do return -1
	neurons := int(width*height)
	if neurons < 2 || neurons > MAX_NEURONS || length != c.size_t(3+PATTERN_COUNT*(1+neurons)) do return -1

	patterns: [PATTERN_COUNT*MAX_NEURONS]i64
	offset := 3
	for pattern in 0..<PATTERN_COUNT {
		label := input[offset]; offset += 1
		if label < 65 || label > 90 do return -1
		for neuron in 0..<neurons {
			cell := input[offset]; offset += 1
			if cell != -1 && cell != 1 do return -1
			patterns[pattern*MAX_NEURONS+neuron] = cell
			if pattern != 0 && cell != patterns[neuron] do return -1
		}
	}
	hamming_warnings := 0
	for first in 0..<PATTERN_COUNT {
		for second in first+1..<PATTERN_COUNT {
			normal, complement := 0, 0
			for neuron in 0..<neurons {
				if patterns[first*MAX_NEURONS+neuron] != patterns[second*MAX_NEURONS+neuron] { normal += 1 }
				if patterns[first*MAX_NEURONS+neuron] != -patterns[second*MAX_NEURONS+neuron] { complement += 1 }
			}
			if normal < 2 { hamming_warnings += 1 }
			if complement < 2 { hamming_warnings += 1 }
		}
	}
	_ = hamming_warnings

	weights: [MAX_NEURONS*MAX_NEURONS]f32
	for pattern in 0..<PATTERN_COUNT {
		for row in 0..<neurons {
			for column in 0..<neurons {
				if row == column { weights[row*neurons+column] = 0 }
				else { weights[row*neurons+column] += f32(patterns[pattern*MAX_NEURONS+row]*patterns[pattern*MAX_NEURONS+column]) }
			}
		}
	}
	converged := false
	for _pass in 0..<1 {
		status := true
		for pattern in 0..<PATTERN_COUNT {
			recalled: [MAX_NEURONS]i64
			if !run_cont(weights[:neurons*neurons], patterns[pattern*MAX_NEURONS:pattern*MAX_NEURONS+neurons], neurons, recalled[:neurons]) do return -2
			correction: [MAX_NEURONS]f32
			for neuron in 0..<neurons {
				correction[neuron] = f32(patterns[pattern*MAX_NEURONS+neuron]-recalled[neuron])*0.5
				if correction[neuron] != 0 { status = false }
			}
			for row in 0..<neurons {
				for column in 0..<neurons {
					if row == column { weights[row*neurons+column] = 0 }
					else { weights[row*neurons+column] += correction[row]*f32(patterns[pattern*MAX_NEURONS+column]) }
				}
			}
		}
		if status { converged = true }
	}
	if !converged do return -2
	stored_count: i64 = 0
	for pattern in 0..<PATTERN_COUNT {
		recalled: [MAX_NEURONS]i64
		if !run_cont(weights[:neurons*neurons], patterns[pattern*MAX_NEURONS:pattern*MAX_NEURONS+neurons], neurons, recalled[:neurons]) do return -2
		stored := true
		for neuron in 0..<neurons { if patterns[pattern*MAX_NEURONS+neuron] != recalled[neuron] { stored = false } }
		if stored { stored_count += 1 }
	}
	return stored_count
}
