// Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
// Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
module mibench_telecomm_fft

import math

fn transform(mut real []f32, mut imag []f32, inverse bool) {
	n := real.len
	mut bits := 0
	mut size := n
	for size > 1 { bits++; size >>= 1 }
	for i in 0 .. n {
		mut source := i
		mut reverse := 0
		for _ in 0 .. bits { reverse = (reverse << 1) | (source & 1); source >>= 1 }
		if i < reverse { real[i], real[reverse] = real[reverse], real[i]; imag[i], imag[reverse] = imag[reverse], imag[i] }
	}
	angle_num := (if inverse { -2.0 } else { 2.0 }) * math.pi
	mut block_end := 1
	mut block := 2
	for block <= n {
		delta := angle_num / f64(block)
		sm2, sm1 := math.sin(-2.0 * delta), math.sin(-delta)
		cm2, cm1 := math.cos(-2.0 * delta), math.cos(-delta)
		w := 2.0 * cm1
		mut start := 0
		for start < n {
			mut ar2, mut ar1, mut ai2, mut ai1 := cm2, cm1, sm2, sm1
			for offset in 0 .. block_end {
				ar0 := w * ar1 - ar2; ar2 = ar1; ar1 = ar0
				ai0 := w * ai1 - ai2; ai2 = ai1; ai1 = ai0
				first := start + offset; second := first + block_end
				tr := ar0 * f64(real[second]) - ai0 * f64(imag[second])
				ti := ar0 * f64(imag[second]) + ai0 * f64(real[second])
				real[second] = f32(f64(real[first]) - tr); imag[second] = f32(f64(imag[first]) - ti)
				real[first] = f32(f64(real[first]) + tr); imag[first] = f32(f64(imag[first]) + ti)
			}
			start += block
		}
		block_end = block
		block *= 2
	}
	if inverse { for i in 0 .. n { real[i] = f32(f64(real[i]) / f64(n)); imag[i] = f32(f64(imag[i]) / f64(n)) } }
}

@[export: 'mibench_telecomm_fft']
pub fn mibench_telecomm_fft(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > 34 { return -1 }
	unsafe {
		nd, inverse := input[0], input[1]
		if nd != nd || inverse != inverse || math.trunc(nd) != nd || math.trunc(inverse) != inverse || nd < 2 || nd > 16 || (inverse != 0 && inverse != 1) { return -1 }
		n := int(nd)
		if n & (n - 1) != 0 || length != usize(2 + 2 * n) { return -1 }
		for i in 2 .. int(length) { if input[i] != input[i] || input[i] < -8 || input[i] > 8 { return -1 } }
		required := 2 * n
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		mut real := []f32{len: n, init: 0}
		mut imag := []f32{len: n, init: 0}
		for i in 0 .. n { real[i] = f32(input[2 + i]); imag[i] = f32(input[2 + n + i]) }
		transform(mut real, mut imag, inverse != 0)
		mut staged := []f64{len: required, init: 0}
		for i in 0 .. n { staged[2 * i] = f64(real[i]); staged[2 * i + 1] = f64(imag[i]) }
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
