module main

import math

const pattern_count = 10
const max_neurons = 8

fn activation(value f32) f32 {
	mut x := f64(value)
	if x > 200.0 { x = 200.0 }
	if x < -200.0 { x = -200.0 }
	e := math.exp(-x)
	return f32((1.0 - e) / (1.0 + e))
}

fn run_cont(weights []f32, source []i64, neurons int, mut dest []i64) bool {
	mut temp_a := [8]f32{}
	mut temp_c := [8]i64{}
	for neuron in 0 .. neurons {
		dest[neuron] = source[neuron]
		temp_a[neuron] = f32(source[neuron])
	}
	mut stable := false
	mut threshold := false
	mut iterations := 0
	for !stable && iterations < 500 {
		mut threshold_iterations := 0
		for row in 0 .. neurons {
			mut sum := f32(0)
			for neuron in 0 .. neurons { sum += weights[row*neurons+neuron] * f32(source[neuron]) }
			temp_a[row] = activation(sum)
		}
		for !threshold && threshold_iterations < 50 {
			threshold = true
			for row in 0 .. neurons {
				if math.abs(f64(temp_a[row])) < 0.7 {
					mut sum := f32(0)
					for neuron in 0 .. neurons { sum += weights[row*neurons+neuron] * temp_a[neuron] }
					temp_a[row] = activation(sum)
					if temp_a[row] < f32(0.7) { threshold = false }
				}
			}
			threshold_iterations++
		}
		mut same := true
		for neuron in 0 .. neurons {
			temp_c[neuron] = if temp_a[neuron] > 0 { 1 } else { -1 }
			if dest[neuron] != temp_c[neuron] { same = false }
		}
		if same { stable = true } else {
			for neuron in 0 .. neurons {
				if dest[neuron] != temp_c[neuron] { dest[neuron] = temp_c[neuron]; break }
			}
			for neuron in 0 .. neurons { temp_a[neuron] = f32(dest[neuron]) }
		}
		iterations++
	}
	return iterations < 500
}

@[export: 'freebench_neural_hopfield']
pub fn freebench_neural_hopfield(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 94 { return -1 }
	width := unsafe { input[0] }
	height := unsafe { input[1] }
	pattern_count_value := unsafe { input[2] }
	if width < 1 || width > 8 || height < 1 || height > 8 || pattern_count_value != pattern_count { return -1 }
	neurons := int(width * height)
	if neurons < 2 || neurons > max_neurons || length != usize(3 + pattern_count * (1 + neurons)) { return -1 }

	mut patterns := [80]i64{}
	mut offset := 3
	for pattern in 0 .. pattern_count {
		label := unsafe { input[offset] }; offset++
		if label < 65 || label > 90 { return -1 }
		for neuron in 0 .. neurons {
			cell := unsafe { input[offset] }; offset++
			if cell != -1 && cell != 1 { return -1 }
			patterns[pattern*max_neurons+neuron] = cell
			if pattern != 0 && cell != patterns[neuron] { return -1 }
		}
	}
	mut hamming_warnings := 0
	for first in 0 .. pattern_count {
		for second in first + 1 .. pattern_count {
			mut normal, mut complement := 0, 0
			for neuron in 0 .. neurons {
				if patterns[first*max_neurons+neuron] != patterns[second*max_neurons+neuron] { normal++ }
				if patterns[first*max_neurons+neuron] != -patterns[second*max_neurons+neuron] { complement++ }
			}
			if normal < 2 { hamming_warnings++ }
			if complement < 2 { hamming_warnings++ }
		}
	}
	_ = hamming_warnings

	mut weights := [64]f32{}
	for pattern in 0 .. pattern_count {
		for row in 0 .. neurons {
			for column in 0 .. neurons {
				if row == column { weights[row*neurons+column] = 0 }
				else { weights[row*neurons+column] += f32(patterns[pattern*max_neurons+row] * patterns[pattern*max_neurons+column]) }
			}
		}
	}
	mut converged := false
	for _ in 0 .. 1 {
		mut status := true
		for pattern in 0 .. pattern_count {
			base := pattern * max_neurons
			mut recalled := [8]i64{}
			if !run_cont(weights[..neurons*neurons], patterns[base..base+neurons], neurons, mut recalled[..neurons]) { return -2 }
			mut correction := [8]f32{}
			for neuron in 0 .. neurons {
				correction[neuron] = f32(patterns[base+neuron] - recalled[neuron]) * f32(0.5)
				if correction[neuron] != 0 { status = false }
			}
			for row in 0 .. neurons {
				for column in 0 .. neurons {
					if row == column { weights[row*neurons+column] = 0 }
					else { weights[row*neurons+column] += correction[row] * f32(patterns[base+column]) }
				}
			}
		}
		if status { converged = true }
	}
	if !converged { return -2 }
	mut stored_count := i64(0)
	for pattern in 0 .. pattern_count {
		base := pattern * max_neurons
		mut recalled := [8]i64{}
		if !run_cont(weights[..neurons*neurons], patterns[base..base+neurons], neurons, mut recalled[..neurons]) { return -2 }
		mut stored := true
		for neuron in 0 .. neurons { if patterns[base+neuron] != recalled[neuron] { stored = false } }
		if stored { stored_count++ }
	}
	return stored_count
}
