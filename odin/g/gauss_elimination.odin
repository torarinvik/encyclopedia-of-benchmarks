package gauss_elimination

import "core:c"
import "core:math"

put_f64_le :: proc "contextless" (out: [^]u8, off: int, value: f64) {
	bits := transmute(u64)value
	for b: int=0; b<8; b+=1 { out[off+b]=u8(bits >> u64(8*b)) }
}

round_even :: proc "contextless" (value: f64) -> f64 {
	low := math.floor(value)
	fraction := value-low
	if fraction < 0.5 do return low
	if fraction > 0.5 do return low+1
	if i64(low) % 2 == 0 { return low }
	return low+1
}

@(export)
gauss_elimination :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 2 || input[0] > 8 do return -1
	n := int(input[0])
	if length != c.size_t(1+n*n+n) do return -1
	for i := 1; i < int(length); i += 1 do if input[i] < -100 || input[i] > 100 do return -1
	m: [72]f32
	for r := 0; r < n; r += 1 { for col := 0; col < n; col += 1 do m[r*9+col]=f32(input[1+r*n+col]); m[r*9+n]=f32(input[1+n*n+r]) }
	for i := 0; i+1 < n; i += 1 {
		pivot := i
		for j := i; j < n; j += 1 do if math.abs(m[j*9+i]) > math.abs(m[pivot*9+i]) do pivot=j
		if m[pivot*9+i] == 0 do return -1
		if pivot != i { for l := 0; l <= n; l += 1 { t := m[i*9+l]; m[i*9+l]=m[pivot*9+l]; m[pivot*9+l]=t } }
		for j := i+1; j < n; j += 1 {
			tmp := -(m[j*9+i]/m[i*9+i])
			for l := 0; l <= n; l += 1 do m[j*9+l]=m[j*9+l]+m[i*9+l]*tmp
		}
	}
	if m[(n-1)*9+n-1] == 0 do return -1
	if output == nil || capacity < c.size_t(n*8) do return -2
	ans: [8]f32
	for k := n; k > 0; {
		k -= 1
		mul: f32=0
		for l := n; l > k+1; { l -= 1; mul=mul+m[k*9+l]*ans[l] }
		ans[k]=(m[k*9+n]-mul)/m[k*9+k]
	}
	for i := 0; i < n; i += 1 do put_f64_le(output, i*8, round_even(f64(ans[i]*100))/100)
	return i64(n*8)
}
