// Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
// Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
package mibench_telecomm_fft

import "core:c"
import "core:math"

transform :: proc "contextless" (real, imag: [^]f32, n: int, inverse: bool) {
	bits := 0
	size := n
	for size > 1 { bits += 1; size >>= 1 }
	for i := 0; i < n; i += 1 {
		source, reverse := i, 0
		for b := 0; b < bits; b += 1 { reverse = (reverse << 1) | (source & 1); source >>= 1 }
		if i < reverse { temporary := real[i]; real[i] = real[reverse]; real[reverse] = temporary; temporary = imag[i]; imag[i] = imag[reverse]; imag[reverse] = temporary }
	}
	angle_num := (if inverse do -2.0 else 2.0) * 3.14159265358979323846
	block_end := 1
	for block := 2; block <= n; block *= 2 {
		delta := angle_num / f64(block)
		sm2, sm1 := math.sin(-2.0*delta), math.sin(-delta)
		cm2, cm1 := math.cos(-2.0*delta), math.cos(-delta)
		w := 2.0 * cm1
		for start := 0; start < n; start += block {
			ar2, ar1, ai2, ai1 := cm2, cm1, sm2, sm1
			for offset := 0; offset < block_end; offset += 1 {
				ar0 := w*ar1-ar2; ar2=ar1; ar1=ar0
				ai0 := w*ai1-ai2; ai2=ai1; ai1=ai0
				first, second := start+offset, start+offset+block_end
				tr := ar0*f64(real[second])-ai0*f64(imag[second])
				ti := ar0*f64(imag[second])+ai0*f64(real[second])
				real[second]=f32(f64(real[first])-tr); imag[second]=f32(f64(imag[first])-ti)
				real[first]=f32(f64(real[first])+tr); imag[first]=f32(f64(imag[first])+ti)
			}
		}
		block_end=block
	}
	if inverse { for i := 0; i < n; i += 1 { real[i]=f32(f64(real[i])/f64(n)); imag[i]=f32(f64(imag[i])/f64(n)) } }
}

@(export)
mibench_telecomm_fft :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 34 do return -1
	nd, inverse := input[0], input[1]
	if nd != nd || inverse != inverse || math.trunc(nd) != nd || math.trunc(inverse) != inverse || nd < 2 || nd > 16 || (inverse != 0 && inverse != 1) do return -1
	n := int(nd)
	if n & (n-1) != 0 || length != c.size_t(2+2*n) do return -1
	for i := 2; i < int(length); i += 1 { if input[i] != input[i] || input[i] < -8 || input[i] > 8 do return -1 }
	required := 2*n
	if output == nil || capacity < c.size_t(required) do return -2
	var real: [16]f32
	var imag: [16]f32
	for i := 0; i < n; i += 1 { real[i]=f32(input[2+i]); imag[i]=f32(input[2+n+i]) }
	transform(&real[0], &imag[0], n, inverse != 0)
	var staged: [32]f64
	for i := 0; i < n; i += 1 { staged[2*i]=f64(real[i]); staged[2*i+1]=f64(imag[i]) }
	for i := 0; i < required; i += 1 { output[i]=staged[i] }
	return i64(required)
}
